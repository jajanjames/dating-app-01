// FILE: lib/data/repositories/subscription_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/authed_api.dart';
import '../models/social_models.dart';

/// Wraps `/subscriptions/*` and `/notifications/fcm-token`.
class SubscriptionRepository {
  SubscriptionRepository(this._api);

  final AuthedApi _api;

  Future<List<SubscriptionPlan>> plans() async {
    final json = asJsonMap(await _api.get('/subscriptions/plans'));
    return [for (final p in asJsonList(json['plans'])) SubscriptionPlan.fromJson(p)];
  }

  Future<SubscriptionStatus> status() async =>
      SubscriptionStatus.fromJson(asJsonMap(await _api.get('/subscriptions/me')));

  /// Fails with `PAYMENTS_DISABLED` until in-app purchases are integrated.
  Future<SubscriptionStatus> activate(String planId) async => SubscriptionStatus.fromJson(
        asJsonMap(await _api.post('/subscriptions/activate', {'planId': planId})),
      );

  Future<void> registerPushToken(String token) =>
      _api.put('/notifications/fcm-token', {'token': token});

  Future<void> unregisterPushToken() => _api.delete('/notifications/fcm-token');
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(ref.watch(authedApiProvider)),
);
