// FILE: lib/features/discovery/discovery_controller.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../data/models/candidate_profile.dart';
import '../../data/models/discover_models.dart';
import '../../data/models/filter_preferences.dart';
import '../../data/repositories/dating_repository.dart';
import '../../data/repositories/discover_repository.dart';
import '../../data/repositories/interests_repository.dart';
import '../matches/chats_controller.dart';
import '../matches/likes_controller.dart';
import '../subscription/subscription_controller.dart';

/// Immutable state for the Naam Discovery screen.
@immutable
class DiscoveryState {
  const DiscoveryState({
    required this.candidates,
    required this.preferences,
    this.nextCursor,
    this.hasMore = false,
    this.isSwiping = false,
    this.swipeError,
    this.swipeErrorNeedsUpgrade = false,
    this.latestMutualMatch,
    this.latestMatchConversationId,
  });

  /// Profiles waiting to be shown; the first one is on screen.
  final List<CandidateProfile> candidates;
  final FilterPreferences preferences;

  /// Opaque cursor for the next `GET /discover` page.
  final String? nextCursor;
  final bool hasMore;

  /// `true` while a swipe request is in flight (ignore further taps).
  final bool isSwiping;
  final String? swipeError;

  /// The swipe was refused because the user needs a plan (or more quota).
  final bool swipeErrorNeedsUpgrade;
  final CandidateProfile? latestMutualMatch;

  /// Chat to open from the "It's a match" dialog.
  final String? latestMatchConversationId;

  CandidateProfile? get currentCandidate =>
      candidates.isNotEmpty ? candidates.first : null;

  /// The API swipes each profile once, so there is nothing to rewind.
  bool get canRewind => false;

  DiscoveryState copyWith({
    List<CandidateProfile>? candidates,
    FilterPreferences? preferences,
    String? nextCursor,
    bool? hasMore,
    bool clearCursor = false,
    bool? isSwiping,
    String? swipeError,
    bool? swipeErrorNeedsUpgrade,
    bool clearSwipeError = false,
    CandidateProfile? latestMutualMatch,
    String? latestMatchConversationId,
    bool clearLatestMatch = false,
  }) {
    return DiscoveryState(
      candidates: candidates ?? this.candidates,
      preferences: preferences ?? this.preferences,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
      isSwiping: isSwiping ?? this.isSwiping,
      swipeError: clearSwipeError ? null : (swipeError ?? this.swipeError),
      swipeErrorNeedsUpgrade: clearSwipeError
          ? false
          : (swipeErrorNeedsUpgrade ?? this.swipeErrorNeedsUpgrade),
      latestMutualMatch: clearLatestMatch
          ? null
          : (latestMutualMatch ?? this.latestMutualMatch),
      latestMatchConversationId: clearLatestMatch
          ? null
          : (latestMatchConversationId ?? this.latestMatchConversationId),
    );
  }
}

/// AsyncNotifier managing the Discovery deck from `GET /discover` and
/// `POST /discover/swipe`, with `loading`, `error`, `empty` and `data` states.
class DiscoveryController extends AsyncNotifier<DiscoveryState> {
  FilterPreferences _preferences = const FilterPreferences();
  Map<String, String> _interestLabels = const {};
  bool _isLoadingMore = false;

  void _bumpActivityRevision() {
    ref.read(datingActivityRevisionProvider.notifier).state++;
  }

  /// Only gender is filterable by the API; distance and ranking are server-side.
  String? get _genderFilter => switch (_preferences.interestedInGender) {
        'Women' => 'FEMALE',
        'Men' => 'MALE',
        'Non-binary' => 'OTHER',
        _ => null,
      };

  @override
  Future<DiscoveryState> build() => _loadFirstPage();

  Future<DiscoveryState> _loadFirstPage() async {
    await _loadInterestLabels();
    final page =
        await ref.read(discoverRepositoryProvider).fetch(gender: _genderFilter);
    return DiscoveryState(
      candidates: _toCandidates(page),
      preferences: _preferences,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  /// Best-effort: labels for interest enums; falls back to prettified values.
  Future<void> _loadInterestLabels() async {
    if (_interestLabels.isNotEmpty) return;
    try {
      final result = await ref.read(interestsRepositoryProvider).fetch();
      _interestLabels = {
        for (final categories in result.options.values)
          for (final c in categories)
            for (final o in c.items) o.value: o.label,
      };
    } on ApiException {
      // Labels are cosmetic; keep going.
    }
  }

  List<CandidateProfile> _toCandidates(DiscoverPage page) => [
        for (final p in page.profiles) p.toCandidate(_interestLabels),
      ];

  Future<void> updatePreferences(FilterPreferences newPreferences) async {
    _preferences = newPreferences;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadFirstPage);
  }

  Future<void> applyFilters(FilterPreferences newPreferences) {
    return updatePreferences(newPreferences);
  }

  /// Dislike, like, or premium like on the current card.
  /// [message] (max 200 chars) is sent with a like / premium like (a note).
  /// Returns `true` when the swipe was saved.
  Future<bool> swipeCurrent({
    required bool isLike,
    bool isSuperLike = false,
    String? message,
  }) async {
    final current = state.valueOrNull;
    final candidate = current?.currentCandidate;
    if (current == null || candidate == null || current.isSwiping) return false;

    final action = !isLike
        ? SwipeAction.dislike
        : (isSuperLike ? SwipeAction.premiumLike : SwipeAction.like);

    state = AsyncData(current.copyWith(isSwiping: true, clearSwipeError: true));

    var matched = false;
    String? conversationId;
    try {
      final result = await ref.read(discoverRepositoryProvider).swipe(
            targetUserId: candidate.id,
            action: action,
            message: message,
          );
      matched = result.isMatch;
      conversationId = result.conversationId;
    } on ApiException catch (e) {
      // 409: already swiped, so just drop the card. Anything else keeps it
      // (403: no plan / quota used up -> the screen offers an upgrade).
      if (e.statusCode != 409) {
        state = AsyncData(
          (state.valueOrNull ?? current).copyWith(
            isSwiping: false,
            swipeError: e.message,
            swipeErrorNeedsUpgrade: e.requiresUpgrade,
          ),
        );
        return false;
      }
    }

    // Local history for the profile tab's "Recent Passes" sheet.
    ref.read(datingRepositoryProvider).recordSwipeAction(
          candidate: candidate,
          isLike: isLike,
          isSuperLike: isSuperLike,
        );
    _bumpActivityRevision();
    if (isLike) {
      // Quotas changed and "Your Likes" grew; matches arrive in Chats.
      ref.invalidate(subscriptionStatusProvider);
      ref.invalidate(likesControllerProvider);
      if (matched) ref.read(chatInboxProvider.notifier).refresh();
    }

    final latest = state.valueOrNull ?? current;
    final remaining =
        latest.candidates.where((c) => c.id != candidate.id).toList();
    state = AsyncData(
      latest.copyWith(
        candidates: remaining,
        isSwiping: false,
        latestMutualMatch: matched ? candidate : null,
        latestMatchConversationId: matched ? conversationId : null,
        clearLatestMatch: !matched,
      ),
    );

    await _loadMoreIfNeeded();
    return true;
  }

  /// Prefetches the next 2 profiles once the queue is nearly empty.
  Future<void> _loadMoreIfNeeded() async {
    final current = state.valueOrNull;
    if (current == null ||
        _isLoadingMore ||
        !current.hasMore ||
        current.candidates.length > 1) {
      return;
    }
    _isLoadingMore = true;
    try {
      final page = await ref
          .read(discoverRepositoryProvider)
          .fetch(cursor: current.nextCursor, gender: _genderFilter);
      final latest = state.valueOrNull ?? current;
      final known = latest.candidates.map((c) => c.id).toSet();
      state = AsyncData(
        latest.copyWith(
          candidates: [
            ...latest.candidates,
            ..._toCandidates(page).where((c) => !known.contains(c.id)),
          ],
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          hasMore: page.hasMore,
        ),
      );
    } on ApiException catch (e) {
      final latest = state.valueOrNull ?? current;
      state = AsyncData(latest.copyWith(swipeError: e.message));
    } finally {
      _isLoadingMore = false;
    }
  }

  /// A note: a like carrying one short [messageText] (max 200 chars), sent
  /// without matching. Returns `true` when it was sent.
  Future<bool> sendIntroMessageFromDiscovery({
    required CandidateProfile candidate,
    required String messageText,
  }) async {
    final text = messageText.trim();
    if (text.isEmpty) return false;
    return swipeCurrent(isLike: true, message: text);
  }

  /// The API has no undo; kept so existing callers compile.
  Future<void> rewindLastSwipe() async {}

  Future<void> resetDeck() async {
    _preferences = const FilterPreferences();
    ref.invalidateSelf();
    await future;
  }

  void dismissMatchCelebration() {
    final currentData = state.valueOrNull;
    if (currentData == null) return;
    state = AsyncData(currentData.copyWith(clearLatestMatch: true));
  }
}

final discoveryControllerProvider =
    AsyncNotifierProvider<DiscoveryController, DiscoveryState>(
  DiscoveryController.new,
);

final filterPreferencesProvider = Provider<FilterPreferences>((ref) {
  final discovery = ref.watch(discoveryControllerProvider).valueOrNull;
  return discovery?.preferences ?? const FilterPreferences();
});
