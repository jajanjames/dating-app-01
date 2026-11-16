// FILE: lib/core/network/mapbox_geocoding_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Mapbox public access token, supplied at build time:
/// `flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.xxxxx`
const String kMapboxAccessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

/// A place with coordinates (sent as LOCATION latitude/longitude).
@immutable
class CityOption {
  const CityOption(this.label, this.latitude, this.longitude);

  final String label;
  final double latitude;
  final double longitude;
}

/// Mapbox Geocoding v6: place search (text → lat/lng) and reverse lookup.
class MapboxGeocodingService {
  MapboxGeocodingService({http.Client? client, String? accessToken})
      : _http = client ?? http.Client(),
        _token = accessToken ?? kMapboxAccessToken;

  final http.Client _http;
  final String _token;

  static const String _host = 'api.mapbox.com';
  static const Duration _timeout = Duration(seconds: 10);

  bool get isConfigured => _token.isNotEmpty;

  /// Searches for cities/localities matching [query].
  Future<List<CityOption>> search(String query, {String country = ''}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final json = await _get('/search/geocode/v6/forward', {
      'q': q,
      'types': 'place,locality,district',
      'autocomplete': 'true',
      'limit': '6',
      if (country.isNotEmpty) 'country': country,
    });
    return _parse(json);
  }

  /// Returns a readable city name for coordinates, or `null` if none found.
  Future<String?> reverse(double latitude, double longitude) async {
    final json = await _get('/search/geocode/v6/reverse', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'types': 'place,locality',
      'limit': '1',
    });
    final results = _parse(json);
    return results.isEmpty ? null : results.first.label;
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> params,
  ) async {
    if (!isConfigured) {
      throw const ApiException(
        'Location search is not configured (missing Mapbox token).',
      );
    }
    try {
      final uri = Uri.https(_host, path, {...params, 'access_token': _token});
      final response = await _http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        throw ApiException(
          response.statusCode == 401
              ? 'Mapbox rejected the access token.'
              : 'Location search failed (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on TimeoutException {
      throw const ApiException('Location search timed out.');
    } on http.ClientException {
      throw const ApiException('Could not reach location search.');
    }
  }

  List<CityOption> _parse(Map<String, dynamic> json) {
    final features = json['features'];
    if (features is! List) return const [];
    final results = <CityOption>[];
    for (final feature in features) {
      if (feature is! Map) continue;
      final props = feature['properties'];
      final coords = feature['geometry'] is Map
          ? (feature['geometry'] as Map)['coordinates']
          : null;
      if (props is! Map || coords is! List || coords.length < 2) continue;
      final lng = coords[0];
      final lat = coords[1];
      final label = (props['full_name'] ?? props['name'])?.toString();
      if (label == null || lng is! num || lat is! num) continue;
      results.add(CityOption(label, lat.toDouble(), lng.toDouble()));
    }
    return results;
  }
}

final mapboxGeocodingProvider =
    Provider<MapboxGeocodingService>((ref) => MapboxGeocodingService());
