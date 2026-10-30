import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

class ApiService {
  final String _baseUrl = AppConfig.baseUrl;

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint, {String? token}) {
    return http
        .get(Uri.parse('$_baseUrl$endpoint'), headers: _headers(token: token))
        .timeout(AppConfig.connectTimeout);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body, {String? token}) {
    return http
        .post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: _headers(token: token),
          body: jsonEncode(body),
        )
        .timeout(AppConfig.connectTimeout);
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body, {String? token}) {
    return http
        .put(
          Uri.parse('$_baseUrl$endpoint'),
          headers: _headers(token: token),
          body: jsonEncode(body),
        )
        .timeout(AppConfig.connectTimeout);
  }

  Future<http.Response> delete(String endpoint, {String? token}) {
    return http
        .delete(Uri.parse('$_baseUrl$endpoint'), headers: _headers(token: token))
        .timeout(AppConfig.connectTimeout);
  }
}
