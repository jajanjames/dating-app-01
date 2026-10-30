// FILE: lib/data/repositories/dating_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/candidate_profile.dart';
import '../models/filter_preferences.dart';
import '../models/match_thread.dart';

/// Repository providing curated Naam profiles, discovery filtering, likes/stars/passes state, and chat threads.
class DatingRepository {
  DatingRepository()
      : _matches = List<MatchThread>.of(_initialMatches),
        _admirers = List<CandidateProfile>.of(_initialAdmirers),
        _likedProfiles = <CandidateProfile>[_catalog[1]],
        _starredProfiles = <CandidateProfile>[],
        _passedProfiles = <CandidateProfile>[];

  final List<MatchThread> _matches;
  final List<CandidateProfile> _admirers;
  final List<CandidateProfile> _likedProfiles;
  final List<CandidateProfile> _starredProfiles;
  final List<CandidateProfile> _passedProfiles;

  static const List<CandidateProfile> _catalog = [
    CandidateProfile(
      id: 'cand-ananya',
      name: 'Ananya Nair',
      age: 27,
      gender: 'Women',
      occupation: 'Designer',
      education: 'National Institute of Design',
      heightLabel: '166 cm (5\'5")',
      zodiac: 'Libra',
      lifestyle: 'Filter chai · Non-smoker',
      drug: 'Never',
      neighborhood: 'Kochi',
      distanceKm: 3,
      bio: 'Chai, good stories & a little spontaneity.',
      whatTheyDo:
          'Brand & Spatial Designer crafting warm tactile spaces, café identities, and hand-bound art books.',
      storyDescription:
          'Happiest at a sunlit outdoor café with a clay cup of masala chai, sketching people and swapping travel stories. I love unhurried conversations that turn a 20-minute coffee into a three-hour walk.',
      lifestyleStory:
          'Weekends usually mean a morning ferry ride to Fort Kochi, hunting for vintage brassware, and cooking coastal curries for friends with old Malayalam and indie records playing.',
      imageUrls: [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=1000&q=85',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=1000&q=85',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=1000&q=85',
      ],
      prompt: ProfilePrompt(
        question: 'A Sunday well spent',
        answer:
            'Rainy afternoon chai on the veranda, a good book, and spontaneous sunset drives by the backwaters.',
      ),
      interests: ['Spatial Design', 'Chai', 'Fort Kochi Walks', 'Vinyl Records'],
      intention: 'Long-term partner',
      likesViewer: true,
      isOnline: true,
      lastSeenLabel: 'Online',
      isRecentMatch: true,
      isVerified: true,
      paidIntroMessage:
          'Your taste in warm minimal spaces caught my eye—chai in Fort Kochi this weekend?',
    ),
    CandidateProfile(
      id: 'cand-rohan',
      name: 'Rohan Varghese',
      age: 29,
      gender: 'Men',
      occupation: 'Architect',
      education: 'CEPT University',
      heightLabel: '181 cm (5\'11")',
      zodiac: 'Taurus',
      lifestyle: 'Specialty coffee · Early riser',
      drug: 'Occasionally',
      neighborhood: 'Bengaluru',
      distanceKm: 8,
      bio: 'Restoring heritage bungalows & brewing pour-over coffee.',
      whatTheyDo:
          'Principal Architect restoring courtyard homes and sustainable timber pavilions across South India.',
      storyDescription:
          'I believe the best architecture feels like a quiet embrace. Outside the studio, you will find me testing single-origin roasts or photographing monsoon light on 35mm film.',
      lifestyleStory:
          'Looking for someone grounded, curious, and always ready for a spontaneous weekend drive to Coorg or a late-night dosa run.',
      imageUrls: [
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=1000&q=85',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=1000&q=85',
        'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=1000&q=85',
      ],
      prompt: ProfilePrompt(
        question: 'The quickest way to my heart',
        answer:
            'Warm cardamom buns and debating courtyard architecture over filter coffee.',
      ),
      interests: ['Architecture', '35mm Film', 'Pour-Over Coffee', 'Road Trips'],
      intention: 'Long-term partner',
      likesViewer: true,
      isOnline: true,
      lastSeenLabel: 'Online',
      isRecentMatch: true,
      isVerified: true,
      paidIntroMessage:
          'I know a hidden courtyard café in Indiranagar you would love.',
    ),
    CandidateProfile(
      id: 'cand-meera',
      name: 'Meera Menon',
      age: 26,
      gender: 'Women',
      occupation: 'Botanical Perfumer',
      education: 'St. Xavier\'s Mumbai',
      heightLabel: '168 cm (5\'6")',
      zodiac: 'Pisces',
      lifestyle: 'Matcha ritual · Dog lover',
      drug: 'Never',
      neighborhood: 'Mumbai',
      distanceKm: 12,
      bio: 'Small-batch scents, art bookshops & coastal walks.',
      whatTheyDo:
          'Independent perfumer blending vetiver, jasmine, and monsoon-earth botanicals in a sunlit Bandra studio.',
      storyDescription:
          'I collect memories by scent—rain on warm terracotta, old paperbacks, and cardamom tea. Looking for someone kind and intentional who appreciates the small details.',
      lifestyleStory:
          'My ideal evening is browsing an independent bookshop, splitting seasonal plates at a neighborhood bistro, and walking by the sea.',
      imageUrls: [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=1000&q=85',
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&w=1000&q=85',
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=1000&q=85',
      ],
      prompt: ProfilePrompt(
        question: 'First date wish list',
        answer:
            'Browsing rare art books at an indie shop followed by iced matcha in a quiet courtyard.',
      ),
      interests: ['Botanical Scents', 'Art Books', 'Ceramics', 'Sea Walks'],
      intention: 'Intention-driven dating',
      likesViewer: true,
      isOnline: false,
      lastSeenLabel: 'Seen 1h ago',
      isRecentMatch: true,
      isVerified: true,
    ),
    CandidateProfile(
      id: 'cand-aarav',
      name: 'Aarav Kurian',
      age: 28,
      gender: 'Men',
      occupation: 'Film Composer',
      education: 'KM Music Conservatory',
      heightLabel: '179 cm (5\'10")',
      zodiac: 'Scorpio',
      lifestyle: 'Vinyl collector · Ocean swimmer',
      drug: 'Socially',
      neighborhood: 'Kochi',
      distanceKm: 5,
      bio: 'Scoring indie cinema on acoustic guitar & analog synths.',
      whatTheyDo:
          'Composer and sound designer scoring independent Malayalam and international short films.',
      storyDescription:
          'When I am not in my home studio surrounded by acoustic guitars and tape machines, I am usually swimming at the beach at dawn or hunting for rare soundtracks.',
      lifestyleStory:
          'We will get along effortlessly if you stay through the end credits just to listen to the closing score.',
      imageUrls: [
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=1000&q=85',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=1000&q=85',
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=1000&q=85',
      ],
      prompt: ProfilePrompt(
        question: 'We will get along if',
        answer:
            'You stay through the end credits just to hear the closing orchestral score.',
      ),
      interests: ['Film Scoring', 'Acoustic Guitar', 'Ocean Swims', 'Cinema'],
      intention: 'Long-term partner',
      likesViewer: true,
      isOnline: false,
      lastSeenLabel: 'Seen 2d ago',
      isRecentMatch: false,
      isVerified: true,
      paidIntroMessage:
          'Scoring a new short film tonight—what soundtrack never gets old for you?',
    ),
  ];

  static final List<CandidateProfile> _initialAdmirers = [
    _catalog[0],
    _catalog[2],
    _catalog[3],
  ];

  static final List<MatchThread> _initialMatches = [
    MatchThread(
      id: 'thread-ananya',
      partner: _catalog[0],
      matchedAtLabel: '2m ago',
      unreadCount: 1,
      messages: const [
        ChatMessage(
          id: 'm-1',
          senderId: 'cand-ananya',
          text:
              'Hey! Your note about filter chai and weekend walks caught my eye—what is your favorite spot in Kochi?',
          sentAtLabel: '2:14 PM',
          isFromViewer: false,
        ),
      ],
    ),
    MatchThread(
      id: 'thread-rohan',
      partner: _catalog[1],
      matchedAtLabel: '1h ago',
      unreadCount: 1,
      messages: const [
        ChatMessage(
          id: 'm-2',
          senderId: 'cand-rohan',
          text: 'Are you free this Sunday for the design biennale preview?',
          sentAtLabel: '1:05 PM',
          isFromViewer: false,
        ),
      ],
    ),
  ];

  List<CandidateProfile> getAllProfiles() =>
      List<CandidateProfile>.unmodifiable(_catalog);

  List<CandidateProfile> getAdmirers() =>
      List<CandidateProfile>.unmodifiable(_admirers);

  List<CandidateProfile> getLikedProfiles() =>
      List<CandidateProfile>.unmodifiable(_likedProfiles);

  List<CandidateProfile> getStarredProfiles() =>
      List<CandidateProfile>.unmodifiable(_starredProfiles);

  List<CandidateProfile> getPassedProfiles() =>
      List<CandidateProfile>.unmodifiable(_passedProfiles);

  bool isStarred(String candidateId) =>
      _starredProfiles.any((c) => c.id == candidateId);

  List<CandidateProfile> getPriorityIntroProfiles() {
    return _catalog
        .where((c) => c.paidIntroMessage != null)
        .toList(growable: false);
  }

  void recordSwipeAction({
    required CandidateProfile candidate,
    required bool isLike,
    required bool isSuperLike,
  }) {
    if (isLike) {
      if (!_likedProfiles.any((c) => c.id == candidate.id)) {
        _likedProfiles.insert(0, candidate);
      }
      if (isSuperLike && !_starredProfiles.any((c) => c.id == candidate.id)) {
        _starredProfiles.insert(0, candidate);
      }
      _passedProfiles.removeWhere((c) => c.id == candidate.id);
    } else {
      if (!_passedProfiles.any((c) => c.id == candidate.id)) {
        _passedProfiles.insert(0, candidate);
      }
    }
  }

  void revertLastActionFor(String candidateId) {
    _likedProfiles.removeWhere((c) => c.id == candidateId);
    _starredProfiles.removeWhere((c) => c.id == candidateId);
    _passedProfiles.removeWhere((c) => c.id == candidateId);
  }

  void removeLikedProfile(String candidateId) {
    _likedProfiles.removeWhere((c) => c.id == candidateId);
    _starredProfiles.removeWhere((c) => c.id == candidateId);
  }

  void restorePassedProfile(CandidateProfile candidate) {
    _passedProfiles.removeWhere((c) => c.id == candidate.id);
    if (!_likedProfiles.any((c) => c.id == candidate.id)) {
      _likedProfiles.insert(0, candidate);
    }
  }

  Future<List<CandidateProfile>> fetchDiscoveryDeck({
    required FilterPreferences preferences,
    required Set<String> excludedIds,
    bool simulateError = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (simulateError) {
      throw Exception('Unable to reach Naam discovery service.');
    }

    return _catalog.where((candidate) {
      if (excludedIds.contains(candidate.id)) return false;
      if (preferences.interestedInGender != 'Everyone' &&
          candidate.gender != preferences.interestedInGender) {
        return false;
      }
      if (candidate.distanceKm > preferences.maxDistanceKm) return false;
      if (candidate.age < preferences.minAge ||
          candidate.age > preferences.maxAge) {
        return false;
      }
      if (preferences.drug != 'Any' && candidate.drug != preferences.drug) {
        return false;
      }
      if (preferences.intention != 'Any' &&
          candidate.intention != preferences.intention) {
        return false;
      }
      if (preferences.verifiedOnly && !candidate.isVerified) return false;
      return true;
    }).toList(growable: false);
  }

  List<MatchThread> getMatches() => List<MatchThread>.unmodifiable(_matches);

  MatchThread registerMutualMatch(
    CandidateProfile candidate, {
    bool isSuperMatch = false,
  }) {
    _admirers.removeWhere((c) => c.id == candidate.id);
    if (!_likedProfiles.any((c) => c.id == candidate.id)) {
      _likedProfiles.insert(0, candidate);
    }

    final existingIndex =
        _matches.indexWhere((t) => t.partner.id == candidate.id);
    if (existingIndex != -1) {
      return _matches[existingIndex];
    }

    final thread = MatchThread(
      id: 'thread-${candidate.id}',
      partner: candidate,
      matchedAtLabel: 'Just now',
      isSuperMatch: isSuperMatch,
      unreadCount: 1,
      messages: [
        ChatMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          senderId: candidate.id,
          text: isSuperMatch
              ? 'Your Star highlight made my day! Would love to hear more about your weekend plans.'
              : 'So glad we matched on Naam! How is your week unfolding?',
          sentAtLabel: 'Just now',
          isFromViewer: false,
        ),
      ],
    );
    _matches.insert(0, thread);
    return thread;
  }

  MatchThread sendDirectMessage({
    required CandidateProfile candidate,
    required String text,
  }) {
    _admirers.removeWhere((c) => c.id == candidate.id);
    if (!_likedProfiles.any((c) => c.id == candidate.id)) {
      _likedProfiles.insert(0, candidate);
    }

    final existingIndex =
        _matches.indexWhere((t) => t.partner.id == candidate.id);
    final newMessage = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'viewer',
      text: text,
      sentAtLabel: 'Just now',
      isFromViewer: true,
    );

    if (existingIndex != -1) {
      final current = _matches[existingIndex];
      final updated = current.copyWith(
        matchedAtLabel: 'Just now',
        unreadCount: 0,
        messages: [...current.messages, newMessage],
      );
      _matches
        ..removeAt(existingIndex)
        ..insert(0, updated);
      return updated;
    }

    final created = MatchThread(
      id: 'thread-${candidate.id}',
      partner: candidate,
      matchedAtLabel: 'Just now',
      unreadCount: 0,
      messages: [newMessage],
    );
    _matches.insert(0, created);
    return created;
  }

  MatchThread? appendViewerMessage({
    required String threadId,
    required String text,
  }) {
    final index = _matches.indexWhere((t) => t.id == threadId);
    if (index == -1) return null;

    final current = _matches[index];
    final updatedMessages = [
      ...current.messages,
      ChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'viewer',
        text: text,
        sentAtLabel: 'Just now',
        isFromViewer: true,
      ),
    ];

    final updated = current.copyWith(
      messages: updatedMessages,
      unreadCount: 0,
    );
    _matches[index] = updated;
    return updated;
  }

  void markThreadRead(String threadId) {
    final index = _matches.indexWhere((t) => t.id == threadId);
    if (index == -1) return;
    _matches[index] = _matches[index].copyWith(unreadCount: 0);
  }
}

final datingRepositoryProvider = Provider<DatingRepository>((ref) {
  return DatingRepository();
});

/// Reactive counter bumping whenever matches, likes, or passes mutate.
final datingActivityRevisionProvider = StateProvider<int>((ref) => 0);
