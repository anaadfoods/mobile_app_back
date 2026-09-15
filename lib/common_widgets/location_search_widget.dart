// lib/common_widgets/location_search_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/models/location_models.dart';
import 'package:grocery_app/services/location_service.dart';

/// Reusable Location Autocomplete Search Widget powered by `flutter_typeahead`
/// and `LocationService` (Google Places API & OpenStreetMap Nominatim).
class LocationSearchWidget extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final ValueChanged<LocationSuggestion> onLocationSelected;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final Duration debounceDuration;
  final FocusNode? focusNode;
  final Color? fillColor;
  final Color? accentColor;
  final BorderRadius? borderRadius;
  final ValueChanged<String>? onChanged;

  const LocationSearchWidget({
    super.key,
    this.controller,
    this.initialValue,
    this.labelText = 'Search City or Location',
    this.hintText = 'Type city, state, or address...',
    this.prefixIcon = Icons.location_on_outlined,
    required this.onLocationSelected,
    this.validator,
    this.enabled = true,
    this.debounceDuration = const Duration(milliseconds: 350),
    this.focusNode,
    this.fillColor,
    this.accentColor,
    this.borderRadius,
    this.onChanged,
  });

  @override
  State<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final LocationService _locationService;
  bool _isInternalController = false;
  bool _isInternalFocusNode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.initialValue ?? '');
      _isInternalController = true;
    }

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _controller.dispose();
    }
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = widget.accentColor ??
        (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen);
    final effectiveFillColor = widget.fillColor ??
        (isDark ? AppColors.darkSurface : AppColors.pureWhite);
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(12);

    return TypeAheadField<LocationSuggestion>(
      controller: _controller,
      focusNode: _focusNode,
      debounceDuration: widget.debounceDuration,
      suggestionsCallback: (search) async {
        if (search.trim().length < 2) return [];
        if (mounted) setState(() => _isLoading = true);
        try {
          final results = await _locationService.searchLocations(search.trim());
          return results;
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
      builder: (context, controller, focusNode) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: widget.enabled,
          validator: widget.validator,
          onChanged: widget.onChanged,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : AppColors.charcoal,
          ),
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : AppColors.charcoal38,
              fontSize: 14,
            ),
            labelStyle: TextStyle(
              color: isDark ? Colors.white70 : AppColors.charcoal70,
            ),
            filled: true,
            fillColor: effectiveFillColor,
            prefixIcon: Icon(widget.prefixIcon, color: accent),
            suffixIcon: _isLoading
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accent,
                      ),
                    ),
                  )
                : (_controller.text.isNotEmpty && widget.enabled)
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: isDark ? Colors.white60 : Colors.black45,
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged?.call('');
                          setState(() {});
                        },
                      )
                    : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: effectiveRadius,
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: effectiveRadius,
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: effectiveRadius,
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: effectiveRadius,
              borderSide: const BorderSide(color: AppColors.softRed, width: 1.5),
            ),
          ),
        );
      },
      itemBuilder: (context, LocationSuggestion suggestion) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      suggestion.mainText,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppColors.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (suggestion.secondaryText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        suggestion.secondaryText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : AppColors.charcoal60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      onSelected: (LocationSuggestion suggestion) async {
        setState(() => _isLoading = true);
        try {
          final resolved = await _locationService.resolveFullLocationDetails(suggestion);
          _controller.text = resolved.mainText.isNotEmpty ? resolved.mainText : resolved.displayName;
          widget.onLocationSelected(resolved);
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
      emptyBuilder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
        child: Row(
          children: [
            Icon(
              Icons.search_off_rounded,
              color: isDark ? Colors.white38 : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'No matching locations found',
              style: TextStyle(
                color: isDark ? Colors.white60 : AppColors.charcoal60,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      loadingBuilder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent,
            ),
          ),
        ),
      ),
      decorationBuilder: (context, child) {
        return Material(
          type: MaterialType.card,
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
          clipBehavior: Clip.antiAlias,
          child: child,
        );
      },
    );
  }
}
