// widgets/select_state.dart
import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import '../models/location_models.dart';
import '../services/location_service.dart';

import 'package:grocery_app/service_locator.dart';

typedef StringCallback = void Function(String? value);

class SelectState extends StatefulWidget {
  final StringCallback? onCountryChanged; // kept for compatibility
  final StringCallback? onStateChanged;
  final StringCallback? onCityChanged;
  final TextStyle? style;
  final String? initialState; // Initial state name to pre-select
  final String? initialCity; // Initial city name to pre-select

  const SelectState({
    super.key,
    this.onCountryChanged,
    this.onStateChanged,
    this.onCityChanged,
    this.style,
    this.initialState,
    this.initialCity,
  });

  @override
  State<SelectState> createState() => _SelectStateState();
}

class _SelectStateState extends State<SelectState> {
  final LocationService _locationService = getIt<LocationService>();

  List<StateModel> _states = [];
  List<CityModel> _cities = [];

  StateModel? _selectedStateModel;
  CityModel? _selectedCityModel;

  bool _loadingStates = false;
  bool _loadingCities = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStates();
    // maintain backward compatibility: call onCountryChanged with null
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCountryChanged?.call(null);
    });
  }

  Future<void> _loadStates() async {
    setState(() {
      _loadingStates = true;
      _error = null;
    });
    try {
      final states = await _locationService.fetchStates();
      setState(() {
        _states = states;
      });

      // Auto-select initial state if provided
      if (!mounted) return;
      if (widget.initialState != null && widget.initialState!.isNotEmpty) {
        final matchingState = states.firstWhere(
          (s) => s.name.toLowerCase() == widget.initialState!.toLowerCase(),
          orElse: () => states.first,
        );
        if (matchingState.name.toLowerCase() ==
            widget.initialState!.toLowerCase()) {
          setState(() => _selectedStateModel = matchingState);
          // Wait for cities to load before potentially auto-selecting
          if (mounted) {
            await _loadCitiesForState(matchingState, autoSelectCity: true);
          }
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingStates = false);
    }
  }

  Future<void> _loadCitiesForState(
    StateModel stateModel, {
    bool autoSelectCity = false,
  }) async {
    setState(() {
      _loadingCities = true;
      _error = null;
      _cities = [];
      if (!autoSelectCity) _selectedCityModel = null;
    });
    try {
      final cities = await _locationService.fetchCities(stateId: stateModel.id);
      setState(() {
        _cities = cities;
      });

      // Auto-select initial city if provided and this is initial load
      if (autoSelectCity &&
          widget.initialCity != null &&
          widget.initialCity!.isNotEmpty) {
        final matchingCity = cities.firstWhere(
          (c) => c.name.toLowerCase() == widget.initialCity!.toLowerCase(),
          orElse: () => cities.first,
        );
        if (matchingCity.name.toLowerCase() ==
            widget.initialCity!.toLowerCase()) {
          setState(() => _selectedCityModel = matchingCity);
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingCities = false);
    }
  }

  void _showSearchableStateDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _SearchableDialog<StateModel>(
            title: 'Select State',
            items: _states,
            getDisplayName: (state) => state.name,
            onSelected: (stateModel) {
              setState(() {
                _selectedStateModel = stateModel;
                _selectedCityModel = null;
                _cities = [];
              });
              widget.onStateChanged?.call(stateModel.name);
              _loadCitiesForState(stateModel);
            },
          ),
    );
  }

  void _showSearchableCityDialog() {
    if (_cities.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => _SearchableDialog<CityModel>(
            title: 'Select City',
            items: _cities,
            getDisplayName: (city) => city.name,
            onSelected: (cityModel) {
              setState(() => _selectedCityModel = cityModel);
              widget.onCityChanged?.call(cityModel.name);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // State label + searchable field
        Text(
          'State',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        _loadingStates
            ? _buildLoadingIndicator('Loading states...')
            : _buildSearchableField(
              theme,
              isDark,
              value: _selectedStateModel?.name,
              hint: 'Search & select state',
              icon: Icons.location_city_rounded,
              onTap: _showSearchableStateDialog,
            ),

        const SizedBox(height: 16),

        // City label + searchable field
        Text(
          'City',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        _loadingCities
            ? _buildLoadingIndicator('Loading cities...')
            : _buildSearchableField(
              theme,
              isDark,
              value: _selectedCityModel?.name,
              hint:
                  _selectedStateModel == null
                      ? 'Select a state first'
                      : (_cities.isEmpty
                          ? 'No cities available'
                          : 'Search & select city'),
              icon: Icons.apartment_rounded,
              onTap: _cities.isEmpty ? null : _showSearchableCityDialog,
              enabled: _selectedStateModel != null && _cities.isNotEmpty,
            ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            'Error: $_error',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingIndicator(String text) {
    return SizedBox(
      height: 56,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchableField(
    ThemeData theme,
    bool isDark, {
    String? value,
    required String hint,
    required IconData icon,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoal : AppColors.parchment,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.charcoal87 : AppColors.parchment,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? hint,
                style:
                    widget.style?.copyWith(
                      color:
                          value != null
                              ? (isDark
                                  ? AppColors.parchment
                                  : AppColors.charcoal87)
                              : theme.hintColor.withValues(alpha: 0.5),
                    ) ??
                    TextStyle(
                      color:
                          value != null
                              ? (isDark
                                  ? AppColors.parchment
                                  : AppColors.charcoal87)
                              : theme.hintColor.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
              ),
            ),
            Icon(
              Icons.search_rounded,
              color:
                  enabled
                      ? theme.colorScheme.primary
                      : theme.hintColor.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Searchable Dialog Widget
class _SearchableDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) getDisplayName;
  final void Function(T) onSelected;

  const _SearchableDialog({
    super.key,
    required this.title,
    required this.items,
    required this.getDisplayName,
    required this.onSelected,
  });

  @override
  State<_SearchableDialog<T>> createState() => _SearchableDialogState<T>();
}

class _SearchableDialogState<T> extends State<_SearchableDialog<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems =
            widget.items
                .where(
                  (item) =>
                      widget.getDisplayName(item).toLowerCase().contains(query),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, color: AppColors.parchment),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.parchment,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.parchment),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type to search...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.primary,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.charcoal : AppColors.parchment,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            // List
            Flexible(
              child:
                  _filteredItems.isEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: theme.hintColor.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No results found',
                                style: TextStyle(color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return ListTile(
                            title: Text(widget.getDisplayName(item)),
                            leading: Icon(
                              Icons.place_outlined,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            onTap: () {
                              widget.onSelected(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
