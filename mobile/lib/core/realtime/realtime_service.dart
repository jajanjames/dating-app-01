// FILE: lib/core/realtime/realtime_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../network/api_client.dart';
import '../storage/auth_storage.dart';

/// Thrown when a socket call cannot be made because the socket is not
/// connected. Callers fall back to REST.
class RealtimeUnavailable implements Exception {
  const RealtimeUnavailable();
}

/// One Socket.IO connection for the whole app session.
///
/// Server events (one stream each, covering every conversation of the user):
/// - [onMessage]  `message`        { conversationId, message, sender, clientId }
/// - [onLike]     `like`           a new like / star / note (LikeItem JSON)
/// - [onMatch]    `match`          { conversation }
/// - [onRead]     `messages_read`  { conversationId, readerId, readAt }
///
/// The socket is closed while the app is in the background so the server
/// sends push notifications instead; it reconnects on resume and fires
/// [onReconnect] so screens can refresh what they missed.
class RealtimeService with WidgetsBindingObserver {
  RealtimeService(this._storage, {this.baseUrl = kNaamApiBaseUrl});

  final AuthStorage _storage;
  final String baseUrl;

  io.Socket? _socket;
  bool _started = false;
  bool _everConnected = false;

  final _message = StreamController<Map<String, dynamic>>.broadcast();
  final _like = StreamController<Map<String, dynamic>>.broadcast();
  final _match = StreamController<Map<String, dynamic>>.broadcast();
  final _read = StreamController<Map<String, dynamic>>.broadcast();
  final _reconnect = StreamController<void>.broadcast();

  Stream<Map<String, dynamic>> get onMessage => _message.stream;
  Stream<Map<String, dynamic>> get onLike => _like.stream;
  Stream<Map<String, dynamic>> get onMatch => _match.stream;
  Stream<Map<String, dynamic>> get onRead => _read.stream;

  /// Fires on every successful connection after the first one.
  Stream<void> get onReconnect => _reconnect.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Connects with the stored access token. Safe to call more than once.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await _connect();
  }

  /// Disconnects for good (e.g. on logout).
  void stop() {
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _disposeSocket();
  }

  /// Sends a chat message; resolves with the server ack
  /// `{ ok: true, message, clientId }` or `{ ok: false, statusCode, code?, message }`.
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String text,
    String? clientId,
  }) {
    return _emitWithAck('message:send', {
      'conversationId': conversationId,
      'text': text,
      if (clientId != null) 'clientId': clientId,
    });
  }

  Future<Map<String, dynamic>> markRead(String conversationId) =>
      _emitWithAck('message:read', {'conversationId': conversationId});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    if (state == AppLifecycleState.paused) {
      _disposeSocket();
    } else if (state == AppLifecycleState.resumed && !isConnected) {
      _connect();
    }
  }

  Future<void> _connect() async {
    final token = await _storage.readAccessToken();
    if (!_started || token == null || token.isEmpty) return;
    _disposeSocket();

    final socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          // socket_io_client caches one Manager per URL; without forceNew a
          // reconnect (or another account) would reuse the old auth token.
          .enableForceNew()
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .build(),
    );

    socket.onConnect((_) {
      if (_everConnected) _reconnect.add(null);
      _everConnected = true;
    });
    socket.onConnectError((error) {
      // An expired / invalid token will never succeed; stop retrying.
      if ('$error'.contains('Unauthorized')) _disposeSocket();
    });
    socket.on('message', (data) => _forward(_message, data));
    socket.on('like', (data) => _forward(_like, data));
    socket.on('match', (data) => _forward(_match, data));
    socket.on('messages_read', (data) => _forward(_read, data));

    _socket = socket..connect();
  }

  void _disposeSocket() {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    socket
      ..clearListeners()
      ..dispose();
  }

  Future<Map<String, dynamic>> _emitWithAck(
      String event, Map<String, dynamic> data) {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      return Future.error(const RealtimeUnavailable());
    }
    final completer = Completer<Map<String, dynamic>>();
    socket.emitWithAck(event, data, ack: (dynamic response) {
      if (completer.isCompleted) return;
      final first =
          response is List && response.isNotEmpty ? response.first : response;
      completer.complete(
        _normalize(first) ??
            {'ok': false, 'statusCode': 500, 'message': 'Bad response'},
      );
    });
    // Throws TimeoutException: the server may still have handled the event.
    return completer.future.timeout(const Duration(seconds: 10));
  }

  void _forward(StreamController<Map<String, dynamic>> sink, dynamic data) {
    final map = _normalize(data);
    if (map != null) sink.add(map);
  }

  /// Socket payloads may arrive as loosely typed maps; round-trip through JSON
  /// so nested maps are `Map<String, dynamic>` like REST responses.
  Map<String, dynamic>? _normalize(dynamic data) {
    if (data is! Map) return null;
    final decoded = jsonDecode(jsonEncode(data));
    return decoded is Map<String, dynamic> ? decoded : null;
  }
}

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(ref.watch(authStorageProvider));
  ref.onDispose(service.stop);
  return service;
});
