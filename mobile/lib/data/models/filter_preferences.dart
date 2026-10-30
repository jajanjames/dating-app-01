// FILE: lib/data/models/filter_preferences.dart
import 'package:flutter/foundation.dart';

/// Immutable discovery filter preferences matching the Naam Filter Sheet:
/// - Age (18-29)
/// - Height in inches (48..96 -> 4'0"-8'0")
/// - Sort By Activity toggle
/// - Expandable accordions: Status, Faith, Community, Mother Tongue, Country, State, Smoking, Drug, Gender
@immutable
class FilterPreferences {
  const FilterPreferences({
    this.interestedInGender = 'Everyone',
    this.maxDistanceKm = 50,
    this.minAge = 18,
    this.maxAge = 29,
    this.minHeightInches = 48,
    this.maxHeightInches = 96,
    this.sortByActivity = false,
    this.status = 'Any',
    this.speaks = 'Any',
    this.faith = 'Any',
    this.community = 'Any',
    this.country = 'Any',
    this.stateRegion = 'Any',
    this.smoking = 'Any',
    this.drug = 'Any',
    this.intention = 'Any',
    this.verifiedOnly = false,
  });

  final String interestedInGender;
  final int maxDistanceKm;
  final int minAge;
  final int maxAge;
  final int minHeightInches;
  final int maxHeightInches;
  final bool sortByActivity;
  final String status;
  final String speaks;
  final String faith;
  final String community;
  final String country;
  final String stateRegion;
  final String smoking;
  final String drug;
  final String intention;
  final bool verifiedOnly;

  static String formatHeightInches(int inches) {
    final feet = inches ~/ 12;
    final rem = inches % 12;
    return "$feet'$rem\"";
  }

  String get heightRangeLabel =>
      '${formatHeightInches(minHeightInches)}-${formatHeightInches(maxHeightInches)}';

  FilterPreferences copyWith({
    String? interestedInGender,
    int? maxDistanceKm,
    int? minAge,
    int? maxAge,
    int? minHeightInches,
    int? maxHeightInches,
    bool? sortByActivity,
    String? status,
    String? speaks,
    String? faith,
    String? community,
    String? country,
    String? stateRegion,
    String? smoking,
    String? drug,
    String? intention,
    bool? verifiedOnly,
  }) {
    return FilterPreferences(
      interestedInGender: interestedInGender ?? this.interestedInGender,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      minHeightInches: minHeightInches ?? this.minHeightInches,
      maxHeightInches: maxHeightInches ?? this.maxHeightInches,
      sortByActivity: sortByActivity ?? this.sortByActivity,
      status: status ?? this.status,
      speaks: speaks ?? this.speaks,
      faith: faith ?? this.faith,
      community: community ?? this.community,
      country: country ?? this.country,
      stateRegion: stateRegion ?? this.stateRegion,
      smoking: smoking ?? this.smoking,
      drug: drug ?? this.drug,
      intention: intention ?? this.intention,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterPreferences &&
        other.interestedInGender == interestedInGender &&
        other.maxDistanceKm == maxDistanceKm &&
        other.minAge == minAge &&
        other.maxAge == maxAge &&
        other.minHeightInches == minHeightInches &&
        other.maxHeightInches == maxHeightInches &&
        other.sortByActivity == sortByActivity &&
        other.status == status &&
        other.speaks == speaks &&
        other.faith == faith &&
        other.community == community &&
        other.country == country &&
        other.stateRegion == stateRegion &&
        other.smoking == smoking &&
        other.drug == drug &&
        other.intention == intention &&
        other.verifiedOnly == verifiedOnly;
  }

  @override
  int get hashCode => Object.hash(
        interestedInGender,
        maxDistanceKm,
        minAge,
        maxAge,
        minHeightInches,
        maxHeightInches,
        sortByActivity,
        status,
        speaks,
        faith,
        community,
        country,
        stateRegion,
        smoking,
        drug,
        intention,
        verifiedOnly,
      );
}
