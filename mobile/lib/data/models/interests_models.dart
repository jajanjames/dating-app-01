// FILE: lib/data/models/interests_models.dart
import 'package:flutter/foundation.dart';

/// The two interest screens. [value] is the API enum.
enum InterestStep {
  stepOne('STEP_ONE'),
  stepTwo('STEP_TWO');

  const InterestStep(this.value);

  final String value;
}

/// One selectable option: [value] (UPPER_SNAKE_CASE) goes to the API, [label]
/// is shown in the UI.
@immutable
class InterestOption {
  const InterestOption({required this.value, required this.label});

  factory InterestOption.fromJson(Map<String, dynamic> json) => InterestOption(
        value: json['value'] as String,
        label: json['label'] as String,
      );

  final String value;
  final String label;
}

/// A section heading with its tags (e.g. "Comfort food").
@immutable
class InterestCategory {
  const InterestCategory({
    required this.key,
    required this.title,
    required this.items,
  });

  factory InterestCategory.fromJson(Map<String, dynamic> json) =>
      InterestCategory(
        key: json['key'] as String? ?? '',
        title: json['title'] as String? ?? '',
        items: json['items'] is List
            ? (json['items'] as List)
                .whereType<Map<String, dynamic>>()
                .map(InterestOption.fromJson)
                .toList()
            : const [],
      );

  final String key;
  final String title;
  final List<InterestOption> items;
}

/// Response of `GET /interests` and `PUT /interests`.
@immutable
class InterestsResult {
  const InterestsResult({
    required this.stepOne,
    required this.stepTwo,
    required this.isComplete,
    required this.options,
  });

  factory InterestsResult.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic v) =>
        v is List ? v.whereType<String>().toList() : const [];

    List<InterestCategory> opts(dynamic v) => v is List
        ? v
            .whereType<Map<String, dynamic>>()
            .map(InterestCategory.fromJson)
            .toList()
        : const [];

    final rawOptions = json['options'];
    final optionMap =
        rawOptions is Map<String, dynamic> ? rawOptions : const {};
    return InterestsResult(
      stepOne: strings(json['stepOne']),
      stepTwo: strings(json['stepTwo']),
      isComplete: json['isComplete'] == true,
      options: {
        InterestStep.stepOne: opts(optionMap[InterestStep.stepOne.value]),
        InterestStep.stepTwo: opts(optionMap[InterestStep.stepTwo.value]),
      },
    );
  }

  final List<String> stepOne;
  final List<String> stepTwo;
  final bool isComplete;
  final Map<InterestStep, List<InterestCategory>> options;

  List<String> selectedFor(InterestStep step) =>
      step == InterestStep.stepOne ? stepOne : stepTwo;

  /// Labels of every saved selection, for display on the profile.
  List<String> get selectedLabels {
    final labels = <String>[];
    for (final step in InterestStep.values) {
      final selected = selectedFor(step);
      for (final category in options[step] ?? const <InterestCategory>[]) {
        for (final option in category.items) {
          if (selected.contains(option.value)) labels.add(option.label);
        }
      }
    }
    return labels;
  }
}
