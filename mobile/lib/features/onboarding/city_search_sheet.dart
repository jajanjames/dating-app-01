// FILE: lib/features/onboarding/city_search_sheet.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/mapbox_geocoding_service.dart';
import '../../core/theme/app_theme.dart';

/// Bottom sheet that searches places via Mapbox and pops the chosen [CityOption].
class CitySearchSheet extends ConsumerStatefulWidget {
  const CitySearchSheet({super.key, required this.suggestions});

  /// Shown before the user types (and as an offline fallback).
  final List<CityOption> suggestions;

  @override
  ConsumerState<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends ConsumerState<CitySearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;
  List<CityOption> _results = const [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _results = widget.suggestions;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _requestId++;
      setState(() {
        _results = widget.suggestions;
        _isLoading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    final id = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await ref.read(mapboxGeocodingProvider).search(query);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = const [];
        _isLoading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isSearching = _controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Text(
                  'Search your city',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: 'e.g. Kochi',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: JDateTokens.brandRose,
                              ),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF4F4F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFD70015)),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: _results.isEmpty && !_isLoading && _error == null
                    ? Center(
                        child: Text(
                          isSearching ? 'No places found' : '',
                          style: const TextStyle(color: Color(0xFF8E8E93)),
                        ),
                      )
                    : ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final city = _results[index];
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF8E8E93),
                            ),
                            title: Text(city.label),
                            onTap: () => Navigator.of(context).pop(city),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
