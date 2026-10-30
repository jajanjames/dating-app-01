// FILE: lib/data/models/candidate_profile.dart
import 'package:flutter/foundation.dart';

/// Represents a single editorial prompt question and answer on a user's profile.
@immutable
class ProfilePrompt {
  const ProfilePrompt({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  ProfilePrompt copyWith({
    String? question,
    String? answer,
  }) {
    return ProfilePrompt(
      question: question ?? this.question,
      answer: answer ?? this.answer,
    );
  }
}

/// Immutable domain model representing a person in the Naam discovery deck, likes, and chats.
@immutable
class CandidateProfile {
  const CandidateProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.occupation,
    required this.education,
    required this.heightLabel,
    required this.zodiac,
    required this.lifestyle,
    required this.neighborhood,
    required this.distanceKm,
    required this.bio,
    required this.imageUrls,
    required this.prompt,
    required this.interests,
    required this.intention,
    required this.likesViewer,
    this.drug = 'Never',
    this.whatTheyDo = '',
    this.storyDescription = '',
    this.lifestyleStory = '',
    this.isOnline = false,
    this.lastSeenLabel = 'Online',
    this.isRecentMatch = false,
    this.isVerified = true,
    this.paidIntroMessage,
  });

  final String id;
  final String name;
  final int age;
  final String gender;
  final String occupation;
  final String education;
  final String heightLabel;
  final String zodiac;
  final String lifestyle;
  final String neighborhood;
  final int distanceKm;
  final String bio;
  final List<String> imageUrls;
  final ProfilePrompt prompt;
  final List<String> interests;
  final String intention;
  final bool likesViewer;
  final String drug;
  final String whatTheyDo;
  final String storyDescription;
  final String lifestyleStory;
  final bool isOnline;
  final String lastSeenLabel;
  final bool isRecentMatch;
  final bool isVerified;
  final String? paidIntroMessage;

  String get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  String get firstName => name.split(' ').first;
  String get jobTitle => occupation;
  List<String> get photoUrls => imageUrls;

  CandidateProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? occupation,
    String? education,
    String? heightLabel,
    String? zodiac,
    String? lifestyle,
    String? neighborhood,
    int? distanceKm,
    String? bio,
    List<String>? imageUrls,
    ProfilePrompt? prompt,
    List<String>? interests,
    String? intention,
    bool? likesViewer,
    String? drug,
    String? whatTheyDo,
    String? storyDescription,
    String? lifestyleStory,
    bool? isOnline,
    String? lastSeenLabel,
    bool? isRecentMatch,
    bool? isVerified,
    String? paidIntroMessage,
  }) {
    return CandidateProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      heightLabel: heightLabel ?? this.heightLabel,
      zodiac: zodiac ?? this.zodiac,
      lifestyle: lifestyle ?? this.lifestyle,
      neighborhood: neighborhood ?? this.neighborhood,
      distanceKm: distanceKm ?? this.distanceKm,
      bio: bio ?? this.bio,
      imageUrls: imageUrls ?? this.imageUrls,
      prompt: prompt ?? this.prompt,
      interests: interests ?? this.interests,
      intention: intention ?? this.intention,
      likesViewer: likesViewer ?? this.likesViewer,
      drug: drug ?? this.drug,
      whatTheyDo: whatTheyDo ?? this.whatTheyDo,
      storyDescription: storyDescription ?? this.storyDescription,
      lifestyleStory: lifestyleStory ?? this.lifestyleStory,
      isOnline: isOnline ?? this.isOnline,
      lastSeenLabel: lastSeenLabel ?? this.lastSeenLabel,
      isRecentMatch: isRecentMatch ?? this.isRecentMatch,
      isVerified: isVerified ?? this.isVerified,
      paidIntroMessage: paidIntroMessage ?? this.paidIntroMessage,
    );
  }
}
