// FILE: lib/features/subscription/subscription_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/social_models.dart';
import '../../data/repositories/subscription_repository.dart';
import '../matches/chats_controller.dart';

/// `GET /subscriptions/me`: active plan, messaging access and remaining quotas.
class SubscriptionController extends AsyncNotifier<SubscriptionStatus> {
  @override
  Future<SubscriptionStatus> build() =>
      ref.read(subscriptionRepositoryProvider).status();

  Future<void> refresh() async {
    final next = await AsyncValue.guard(ref.read(subscriptionRepositoryProvider).status);
    if (next.hasValue || !state.hasValue) state = next;
  }

  /// Throws ApiException (e.g. `PAYMENTS_DISABLED`) on failure.
  Future<SubscriptionStatus> activate(String planId) async {
    final status = await ref.read(subscriptionRepositoryProvider).activate(planId);
    state = AsyncData(status);
    ref.read(chatInboxProvider.notifier).setCanMessage(status.canMessage);
    return status;
  }
}

final subscriptionStatusProvider =
    AsyncNotifierProvider<SubscriptionController, SubscriptionStatus>(
  SubscriptionController.new,
);

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>(
  (ref) => ref.read(subscriptionRepositoryProvider).plans(),
);

/// Id of the active plan, or null.
final activeSubscriptionPlanProvider = Provider<String?>(
  (ref) => ref.watch(subscriptionStatusProvider).valueOrNull?.planId,
);
