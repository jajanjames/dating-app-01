// FILE: lib/features/discovery/widgets/filter_preferences_sheet.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/filter_preferences.dart';

/// Full-Screen Clean White Filter / Preferences View:
/// - Top bar: Solid black rounded "Reset" button on left, downward chevron ("⌄") collapse button on right
/// - Always-visible inline Age (18-29) dual-thumb range slider
/// - Always-visible inline Height (4'0"-8'0") dual-thumb range slider
/// - "Sort By Activity" row with iOS switch
/// - Expandable accordion rows: Status, Faith, Community, Mother Tongue, Country, State, Smoking, Drug, Interested In
/// - Sticky bottom full-width "Save Search" CTA button in #F93666
class FilterPreferencesSheet extends StatefulWidget {
  const FilterPreferencesSheet({
    super.key,
    required this.initialPreferences,
    required this.onApply,
  });

  final FilterPreferences initialPreferences;
  final ValueChanged<FilterPreferences> onApply;

  @override
  State<FilterPreferencesSheet> createState() => _FilterPreferencesSheetState();
}

class _FilterPreferencesSheetState extends State<FilterPreferencesSheet> {
  late RangeValues _ageRange;
  late RangeValues _heightInchesRange;
  late bool _sortByActivity;
  late String _status;
  late String _faith;
  late String _community;
  late String _motherTongue;
  late String _country;
  late String _stateRegion;
  late String _smoking;
  late String _drug;
  late String _interestedInGender;
  String? _expandedKey;

  static const List<String> _statusOptions = [
    'Any',
    'Single',
    'Divorced',
    'Widowed',
    'Separated',
  ];
  static const List<String> _faithOptions = [
    'Any',
    'Christian',
    'Hindu',
    'Muslim',
    'Spiritual',
  ];
  static const List<String> _communityOptions = [
    'Any',
    'Syro-Malabar',
    'Malankara Orthodox',
    'Marthoma',
    'Roman Catholic',
    'Jacobite',
    'Latin Catholic',
  ];
  static const List<String> _motherTongueOptions = [
    'Any',
    'Malayalam',
    'English',
    'Tamil',
    'Hindi',
    'Kannada',
    'Telugu',
  ];
  static const List<String> _countryOptions = [
    'Any',
    'India',
    'United States',
    'United Kingdom',
    'UAE',
    'Canada',
    'Australia',
  ];
  static const List<String> _stateOptions = [
    'Any',
    'Kerala',
    'Karnataka',
    'Tamil Nadu',
    'Maharashtra',
    'Delhi NCR',
  ];
  static const List<String> _smokingOptions = [
    'Any',
    'Non-Smoker',
    'Socially',
    'Regular',
    'Trying to Quit',
  ];
  static const List<String> _drugOptions = [
    'Any',
    'Never',
    'Occasionally',
    'Socially',
    'Cannabis',
    '420 Friendly',
  ];
  static const List<String> _genderOptions = ['Everyone', 'Women', 'Men'];

  @override
  void initState() {
    super.initState();
    _syncFromPreferences(widget.initialPreferences);
  }

  void _syncFromPreferences(FilterPreferences prefs) {
    final startAge = prefs.minAge.clamp(18, 59).toDouble();
    final endAge = prefs.maxAge.clamp(startAge.toInt() + 1, 60).toDouble();
    _ageRange = RangeValues(startAge, endAge);

    final startHeight = prefs.minHeightInches.clamp(48, 95).toDouble();
    final endHeight =
        prefs.maxHeightInches.clamp(startHeight.toInt() + 1, 96).toDouble();
    _heightInchesRange = RangeValues(startHeight, endHeight);

    _sortByActivity = prefs.sortByActivity;
    _status = prefs.status;
    _faith = prefs.faith;
    _community = prefs.community;
    _motherTongue = prefs.speaks;
    _country = prefs.country;
    _stateRegion = prefs.stateRegion;
    _smoking = prefs.smoking;
    _drug = prefs.drug;
    _interestedInGender = prefs.interestedInGender;
  }

  void _handleReset() {
    const defaults = FilterPreferences();
    setState(() {
      _syncFromPreferences(defaults);
      _expandedKey = null;
    });
    widget.onApply(defaults);
  }

  void _saveSearchAndClose() {
    widget.onApply(
      FilterPreferences(
        interestedInGender: _interestedInGender,
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
        minHeightInches: _heightInchesRange.start.round(),
        maxHeightInches: _heightInchesRange.end.round(),
        sortByActivity: _sortByActivity,
        status: _status,
        faith: _faith,
        community: _community,
        speaks: _motherTongue,
        country: _country,
        stateRegion: _stateRegion,
        smoking: _smoking,
        drug: _drug,
      ),
    );
    Navigator.of(context).pop();
  }

  void _toggleExpanded(String key) {
    setState(() {
      _expandedKey = _expandedKey == key ? null : key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final minAgeInt = _ageRange.start.round();
    final maxAgeInt = _ageRange.end.round();
    final minHeightInt = _heightInchesRange.start.round();
    final maxHeightInt = _heightInchesRange.end.round();
    final heightLabel =
        '${FilterPreferences.formatHeightInches(minHeightInt)}-${FilterPreferences.formatHeightInches(maxHeightInt)}';

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                children: [
                  // Top Bar: Solid Black "Reset" Button on Left, Downward Chevron on Right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ResetBlackButton(onPressed: _handleReset),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: JDateTokens.pitchBlack,
                          size: 32,
                        ),
                        tooltip: 'Collapse Filter',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. Inline Age Range Slider (18-29)
                  _InlineRangeSliderSection(
                    title: 'Age',
                    valueLabel: '$minAgeInt-$maxAgeInt',
                    values: _ageRange,
                    min: 18,
                    max: 60,
                    onChanged: (values) {
                      if (values.end - values.start < 1) return;
                      setState(() => _ageRange = values);
                    },
                  ),
                  const SizedBox(height: 18),

                  // 2. Inline Height Range Slider (4'0"-8'0")
                  _InlineRangeSliderSection(
                    title: 'Height',
                    valueLabel: heightLabel,
                    values: _heightInchesRange,
                    min: 48,
                    max: 96,
                    onChanged: (values) {
                      if (values.end - values.start < 1) return;
                      setState(() => _heightInchesRange = values);
                    },
                  ),
                  const SizedBox(height: 14),

                  // 3. Sort By Activity Row with iOS Switch
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sort By Activity',
                          style: TextStyle(
                            color: JDateTokens.pitchBlack,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        CupertinoSwitch(
                          value: _sortByActivity,
                          activeTrackColor: JDateTokens.brandRose,
                          onChanged: (val) =>
                              setState(() => _sortByActivity = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 4. Expandable Accordion Rows
                  _FilterAccordionRow(
                    label: 'Status',
                    selectedValue: _status,
                    isExpanded: _expandedKey == 'status',
                    options: _statusOptions,
                    onToggle: () => _toggleExpanded('status'),
                    onSelect: (val) => setState(() => _status = val),
                  ),
                  _FilterAccordionRow(
                    label: 'Faith',
                    selectedValue: _faith,
                    isExpanded: _expandedKey == 'faith',
                    options: _faithOptions,
                    onToggle: () => _toggleExpanded('faith'),
                    onSelect: (val) => setState(() => _faith = val),
                  ),
                  _FilterAccordionRow(
                    label: 'Community',
                    selectedValue: _community,
                    isExpanded: _expandedKey == 'community',
                    options: _communityOptions,
                    onToggle: () => _toggleExpanded('community'),
                    onSelect: (val) => setState(() => _community = val),
                  ),
                  _FilterAccordionRow(
                    label: 'Mother Tongue',
                    selectedValue: _motherTongue,
                    isExpanded: _expandedKey == 'motherTongue',
                    options: _motherTongueOptions,
                    onToggle: () => _toggleExpanded('motherTongue'),
                    onSelect: (val) => setState(() => _motherTongue = val),
                  ),
                  _FilterAccordionRow(
                    label: 'Country',
                    selectedValue: _country,
                    isExpanded: _expandedKey == 'country',
                    options: _countryOptions,
                    onToggle: () => _toggleExpanded('country'),
                    onSelect: (val) => setState(() => _country = val),
                  ),
                  _FilterAccordionRow(
                    label: 'State',
                    selectedValue: _stateRegion,
                    isExpanded: _expandedKey == 'state',
                    options: _stateOptions,
                    onToggle: () => _toggleExpanded('state'),
                    onSelect: (val) => setState(() => _stateRegion = val),
                  ),
                  _FilterAccordionRow(
                    label: 'Smoking',
                    selectedValue: _smoking,
                    isExpanded: _expandedKey == 'smoking',
                    options: _smokingOptions,
                    onToggle: () => _toggleExpanded('smoking'),
                    onSelect: (val) => setState(() => _smoking = val),
                  ),
                  _FilterAccordionRow(
                    label: 'Drug',
                    selectedValue: _drug,
                    isExpanded: _expandedKey == 'drug',
                    options: _drugOptions,
                    onToggle: () => _toggleExpanded('drug'),
                    onSelect: (val) => setState(() => _drug = val),
                  ),
                  _FilterAccordionRow(
                    label: 'Interested In',
                    selectedValue: _interestedInGender,
                    isExpanded: _expandedKey == 'gender',
                    options: _genderOptions,
                    onToggle: () => _toggleExpanded('gender'),
                    onSelect: (val) =>
                        setState(() => _interestedInGender = val),
                  ),
                ],
              ),
            ),

            // Sticky Bottom Save Search Button (#F93666)
            Container(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF3F3F6), width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: JDateTokens.brandRose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _saveSearchAndClose,
                  child: const Text(
                    'Save Search',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetBlackButton extends StatelessWidget {
  const _ResetBlackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: JDateTokens.pitchBlack,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Reset',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _InlineRangeSliderSection extends StatelessWidget {
  const _InlineRangeSliderSection({
    required this.title,
    required this.valueLabel,
    required this.values,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final String valueLabel;
  final RangeValues values;
  final double min;
  final double max;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: JDateTokens.pitchBlack,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                color: JDateTokens.pitchBlack,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF1E1B4B),
            inactiveTrackColor: const Color(0xFFF1F1F4),
            trackHeight: 4.0,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 13.0,
              elevation: 3.0,
            ),
            thumbColor: Colors.white,
            overlayColor: const Color(0x1FF93666),
          ),
          child: RangeSlider(
            values: values,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _FilterAccordionRow extends StatelessWidget {
  const _FilterAccordionRow({
    required this.label,
    required this.selectedValue,
    required this.isExpanded,
    required this.options,
    required this.onToggle,
    required this.onSelect,
  });

  final String label;
  final String selectedValue;
  final bool isExpanded;
  final List<String> options;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDefault = selectedValue == 'Any' || selectedValue == 'Everyone';

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F3F6), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: (!isDefault || isExpanded)
                          ? JDateTokens.pitchBlack
                          : const Color(0xFFA1A1AA),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    children: [
                      if (!isDefault)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            selectedValue,
                            style: const TextStyle(
                              color: JDateTokens.brandRose,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: isExpanded
                            ? JDateTokens.pitchBlack
                            : const Color(0xFFA1A1AA),
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((opt) {
                  return _SelectableFilterPill(
                    label: opt,
                    isSelected: selectedValue == opt,
                    onTap: () => onSelect(opt),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectableFilterPill extends StatelessWidget {
  const _SelectableFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? JDateTokens.brandRose : const Color(0xFFF4F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? JDateTokens.brandRose : const Color(0xFFE4E4E7),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected ? Colors.white : JDateTokens.pitchBlack,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
