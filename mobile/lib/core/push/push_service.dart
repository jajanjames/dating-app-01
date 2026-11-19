// FILE: lib/core/push/push_service.dart
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/subscription_repository.dart';
import '../router/app_router.dart';

/// Firebase Cloud Messaging: asks permission, registers this app instance's
/// Firebase Installation ID (FID) with the backend
/// (`PUT /notifications/fcm-token`) and opens the right screen when a
/// notification is tapped.
///
/// The server only pushes while the socket is disconnected (app in the
/// background or closed), so the system tray shows them; in the foreground
/// the socket updates the UI directly.
///
/// Requires Firebase config: run `flutterfire configure` (adds
/// google-services.json / GoogleService-Info.plist). Without it, push is
/// skipped and the rest of the app works.
class PushService {
  PushService(this._ref);

  final Ref _ref;
  bool _started = false;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Push notifications disabled (Firebase not configured): $e');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // onRegistered fires with the FID now and again whenever it changes.
      _subscriptions
        ..add(messaging.onRegistered.listen(_register))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
      await messaging.register();

      final initial = await messaging.getInitialMessage();
      if (initial != null) _open(initial);
    } catch (e) {
      debugPrint('Push setup failed: $e');
    }
  }

  /// Stop pushes for this user (call on logout, before clearing the session).
  Future<void> unregister() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    _started = false;
    try {
      await _ref.read(subscriptionRepositoryProvider).unregisterPushToken();
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> _register(String fid) async {
    try {
      await _ref.read(subscriptionRepositoryProvider).registerPushToken(fid);
    } catch (e) {
      debugPrint('Could not register push token: $e');
    }
  }

  /// `data.type`: `message` | `match` -> chat, `like` | `note` -> Likes tab.
  void _open(RemoteMessage message) {
    final router = _ref.read(appRouterProvider);
    final type = message.data['type'];
    final conversationId = message.data['conversationId'];
    if ((type == 'message' || type == 'match') && conversationId is String) {
      router.go(AppRoutes.chats);
      router.push('${AppRoutes.chat}/$conversationId');
    } else if (type == 'like' || type == 'note') {
      router.go(AppRoutes.likes);
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));
