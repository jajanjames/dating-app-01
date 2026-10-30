// FILE: lib/features/discovery/discovery_controller.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/candidate_profile.dart';
import '../../data/models/filter_preferences.dart';
import '../../data/repositories/dating_repository.dart';

/// Immutable state for the Naam Discovery screen.
@immutable
class DiscoveryState {
  const DiscoveryState({
    required this.candidates,
    required this.preferences,
    required this.swipedHistory,
    this.latestMutualMatch,
  });

  final List<CandidateProfile> candidates;
  final FilterPreferences preferences;
  final List<String> swipedHistory;
  final CandidateProfile? latestMutualMatch;

  CandidateProfile? get currentCandidate =>
      candidates.isNotEmpty ? candidates.first : null;

  bool get canRewind => swipedHistory.isNotEmpty;

  DiscoveryState copyWith({
    List<CandidateProfile>? candidates,
    FilterPreferences? preferences,
    List<String>? swipedHistory,
    CandidateProfile? latestMutualMatch,
    bool clearLatestMatch = false,
  }) {
    return DiscoveryState(
      candidates: candidates ?? this.candidates,
      preferences: preferences ?? this.preferences,
      swipedHistory: swipedHistory ?? this.swipedHistory,
      latestMutualMatch: clearLatestMatch
          ? null
          : (latestMutualMatch ?? this.latestMutualMatch),
    );
  }
}

/// AsyncNotifier managing the Discovery deck with 4-state coverage (`loading`, `error`, `empty`, `data`).
class DiscoveryController extends AsyncNotifier<DiscoveryState> {
  FilterPreferences _preferences = const FilterPreferences();
  final List<String> _swipedIds = <String>[];

  void _bumpActivityRevision() {
    ref.read(datingActivityRevisionProvider.notifier).state++;
  }

  @override
  Future<DiscoveryState> build() async {
    final repository = ref.watch(datingRepositoryProvider);
    final list = await repository.fetchDiscoveryDeck(
      preferences: _preferences,
      excludedIds: _swipedIds.toSet(),
    );
    return DiscoveryState(
      candidates: list,
      preferences: _preferences,
      swipedHistory: List<String>.unmodifiable(_swipedIds),
    );
  }

  Future<void> updatePreferences(FilterPreferences newPreferences) async {
    _preferences = newPreferences;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(datingRepositoryProvider);
      final list = await repository.fetchDiscoveryDeck(
        preferences: _preferences,
        excludedIds: _swipedIds.toSet(),
      );
      return DiscoveryState(
        candidates: list,
        preferences: _preferences,
        swipedHistory: List<String>.unmodifiable(_swipedIds),
      );
    });
  }

  Future<void> applyFilters(FilterPreferences newPreferences) {
    return updatePreferences(newPreferences);
  }

  Future<void> swipeCurrent({
    required bool isLike,
    bool isSuperLike = false,
  }) async {
    final currentData = state.valueOrNull;
    final activeCandidate = currentData?.currentCandidate;
    if (currentData == null || activeCandidate == null) return;

    final repository = ref.read(datingRepositoryProvider);
    repository.recordSwipeAction(
      candidate: activeCandidate,
      isLike: isLike,
      isSuperLike: isSuperLike,
    );

    _swipedIds.add(activeCandidate.id);
    CandidateProfile? matched;

    if (isLike && activeCandidate.likesViewer) {
      repository.registerMutualMatch(
        activeCandidate,
        isSuperMatch: isSuperLike,
      );
      matched = activeCandidate;
    }

    _bumpActivityRevision();

    final remaining = currentData.candidates.skip(1).toList(growable: false);
    state = AsyncData(
      currentData.copyWith(
        candidates: remaining,
        swipedHistory: List<String>.unmodifiable(_swipedIds),
        latestMutualMatch: matched,
        clearLatestMatch: matched == null,
      ),
    );
  }

  Future<void> sendIntroMessageFromDiscovery({
    required CandidateProfile candidate,
    required String messageText,
  }) async {
    if (messageText.trim().isEmpty) return;
    ref.read(datingRepositoryProvider).sendDirectMessage(
          candidate: candidate,
          text: messageText.trim(),
        );
    _bumpActivityRevision();
    await swipeCurrent(isLike: true, isSuperLike: true);
  }

  Future<void> rewindLastSwipe() async {
    if (_swipedIds.isEmpty) return;
    final lastId = _swipedIds.removeLast();
    final repository = ref.read(datingRepositoryProvider);
    repository.revertLastActionFor(lastId);
    _bumpActivityRevision();

    final list = await repository.fetchDiscoveryDeck(
      preferences: _preferences,
      excludedIds: _swipedIds.toSet(),
    );
    state = AsyncData(
      DiscoveryState(
        candidates: list,
        preferences: _preferences,
        swipedHistory: List<String>.unmodifiable(_swipedIds),
      ),
    );
  }

  Future<void> resetDeck() async {
    _swipedIds.clear();
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
