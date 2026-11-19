// FILE: lib/core/network/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Base URL of the Naam backend.
const String kNaamApiBaseUrl = 'https://naam.gredin.app';

/// Error thrown for any failed API call, carrying a user-presentable message.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;

  /// Machine-readable reason from the backend, e.g. `SUBSCRIPTION_REQUIRED`,
  /// `LIMIT_REACHED` or `PAYMENTS_DISABLED`.
  final String? code;

  /// The user must buy or upgrade a plan to do this.
  bool get requiresUpgrade =>
      code == 'SUBSCRIPTION_REQUIRED' || code == 'LIMIT_REACHED';

  @override
  String toString() => message;
}

/// A file to send in a multipart request.
class UploadFile {
  const UploadFile({required this.path, this.mimeType = 'image/jpeg'});

  final String path;
  final String mimeType;
}

/// Thin JSON/multipart HTTP client for the Naam backend.
class ApiClient {
  ApiClient({http.Client? httpClient, this.baseUrl = kNaamApiBaseUrl})
      : _http = httpClient ?? http.Client();

  final http.Client _http;
  final String baseUrl;

  static const Duration _jsonTimeout = Duration(seconds: 20);
  static const Duration _uploadTimeout = Duration(seconds: 90);

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> postJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) {
    return _guard(() async {
      final response = await _http
          .post(
            _uri(path),
            headers: _jsonHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(_jsonTimeout);
      return _decode(response);
    });
  }

  /// Authenticated GET. [token] is sent as `Authorization: Bearer <token>`.
  Future<dynamic> getJson(String path, {String? token}) {
    return _guard(() async {
      final response = await _http
          .get(_uri(path), headers: _jsonHeaders(token))
          .timeout(_jsonTimeout);
      return _decode(response);
    });
  }

  /// Authenticated PUT with a JSON [body].
  Future<dynamic> putJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) {
    return _guard(() async {
      final response = await _http
          .put(
            _uri(path),
            headers: _jsonHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(_jsonTimeout);
      return _decode(response);
    });
  }

  /// Authenticated DELETE.
  Future<dynamic> deleteJson(String path, {String? token}) {
    return _guard(() async {
      final response = await _http
          .delete(_uri(path), headers: _jsonHeaders(token))
          .timeout(_jsonTimeout);
      return _decode(response);
    });
  }

  Map<String, String> _jsonHeaders(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required List<UploadFile> files,
  }) {
    return _guard(() async {
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers['Accept'] = 'application/json'
        ..fields.addAll(fields);
      for (final file in files) {
        request.files.add(
          await http.MultipartFile.fromPath(
            fileField,
            file.path,
            contentType: MediaType.parse(file.mimeType),
          ),
        );
      }
      final streamed = await _http.send(request).timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    });
  }

  Future<dynamic> _guard(Future<dynamic> Function() run) async {
    try {
      return await run();
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        'No internet connection. Check your network and try again.',
      );
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } on http.ClientException {
      throw const ApiException('Could not reach the server. Please try again.');
    }
  }

  dynamic _decode(http.Response response) {
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        body = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      _extractMessage(body) ?? 'Something went wrong (${response.statusCode}).',
      statusCode: response.statusCode,
      code:
          body is Map && body['code'] is String ? body['code'] as String : null,
    );
  }

  /// NestJS errors look like `{ message: string | string[], error, statusCode }`.
  String? _extractMessage(dynamic body) {
    if (body is Map) {
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) {
        return message.map((m) => m.toString()).join('\n');
      }
      final error = body['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    if (body is String && body.isNotEmpty && body.length < 200) return body;
    return null;
  }
}
