// FILE: lib/core/network/mapbox_geocoding_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_search/mapbox_search.dart' as mb;

import 'api_client.dart';

/// Mapbox public access token, supplied at build time:
/// `flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.xxxxx`
const String kMapboxAccessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

/// A place with coordinates (sent as LOCATION latitude/longitude).
@immutable
class CityOption {
  const CityOption(this.label, this.latitude, this.longitude)
      : mapboxId = null;

  /// A Mapbox search suggestion whose coordinates are not known yet; call
  /// [MapboxGeocodingService.resolve] to fetch them.
  const CityOption.suggestion(this.label, String this.mapboxId)
      : latitude = 0,
        longitude = 0;

  final String label;
  final double latitude;
  final double longitude;
  final String? mapboxId;

  /// `true` once [latitude]/[longitude] are real coordinates.
  bool get isResolved => mapboxId == null;
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

  /// Searches places matching [query] with the Mapbox Search Box SDK.
  ///
  /// Results are suggestions without coordinates; pass the chosen one to
  /// [resolve]. Results are biased towards the user's IP location (nearby).
  Future<List<CityOption>> search(String query, {String country = ''}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    _ensureConfigured();
    final api = mb.SearchBoxAPI(
      apiKey: _token,
      limit: 8,
      country: country.isEmpty ? null : country,
      types: const [
        mb.PlaceType.place,
        mb.PlaceType.locality,
        mb.PlaceType.neighborhood,
        mb.PlaceType.district,
      ],
    );
    final response = await api.getSuggestions(
      q,
      proximity: mb.Proximity.LocationIp(),
    );
    final data = response.success;
    if (data == null) throw _failure(response.failure);
    return [
      for (final s in data.suggestions)
        CityOption.suggestion(_label(s.name, s.placeFormatted), s.mapboxId),
    ];
  }

  /// Fetches the coordinates for a [CityOption] returned by [search].
  Future<CityOption> resolve(CityOption option) async {
    final id = option.mapboxId;
    if (id == null) return option;
    _ensureConfigured();
    final response = await mb.SearchBoxAPI(apiKey: _token).getPlace(id);
    final data = response.success;
    if (data == null) throw _failure(response.failure);
    for (final feature in data.features) {
      final coords = feature.properties.coordinates?.location;
      if (coords == null) continue;
      return CityOption(option.label, coords.lat, coords.long);
    }
    throw const ApiException('Could not get coordinates for that place.');
  }

  String _label(String name, String? formatted) =>
      (formatted == null || formatted.isEmpty) ? name : '$name, $formatted';

  void _ensureConfigured() {
    if (!isConfigured) {
      throw const ApiException(
        'Location search is not configured (missing Mapbox token).',
      );
    }
  }

  ApiException _failure(mb.FailureResponse? failure) {
    final code = int.tryParse(failure?.code ?? '');
    return ApiException(
      code == 401
          ? 'Mapbox rejected the access token.'
          : 'Location search failed. Please try again.',
      statusCode: code,
    );
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
