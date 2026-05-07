import 'package:grocery_app/core/theme/app_colors.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Utility class for extracting dominant colors from images
class ColorExtractor {
  /// Cache for extracted colors to avoid re-processing
  static final Map<String, Color> _colorCache = {};

  /// Extracts the dominant color from a network image URL
  /// Returns a fallback color if extraction fails
  static Future<Color> extractDominantColor(
    String imageUrl, {
    Color fallbackColor = AppColors.parchment, // Default green
  }) async {
    // Check cache first
    if (_colorCache.containsKey(imageUrl)) {
      return _colorCache[imageUrl]!;
    }

    try {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(100, 100), // Smaller size for faster processing
        maximumColorCount: 10,
      );

      // Try to get the most vibrant/dominant color
      Color? extractedColor;

      // Priority: Vibrant > Dominant > Muted
      if (paletteGenerator.vibrantColor != null) {
        extractedColor = paletteGenerator.vibrantColor!.color;
      } else if (paletteGenerator.dominantColor != null) {
        extractedColor = paletteGenerator.dominantColor!.color;
      } else if (paletteGenerator.mutedColor != null) {
        extractedColor = paletteGenerator.mutedColor!.color;
      } else if (paletteGenerator.colors.isNotEmpty) {
        extractedColor = paletteGenerator.colors.first;
      }

      final resultColor = extractedColor ?? fallbackColor;

      // Cache the result
      _colorCache[imageUrl] = resultColor;

      return resultColor;
    } catch (e) {
      debugPrint('ColorExtractor: Failed to extract color from $imageUrl: $e');
      return fallbackColor;
    }
  }

  /// Pre-extracts colors from multiple image URLs
  /// Useful for pre-loading carousel image colors
  static Future<List<Color>> extractColorsFromUrls(
    List<String> imageUrls, {
    Color fallbackColor = AppColors.parchment,
  }) async {
    final List<Future<Color>> futures = imageUrls.map((url) {
      return extractDominantColor(url, fallbackColor: fallbackColor);
    }).toList();

    return await Future.wait(futures);
  }

  /// Creates a softened version of the color for backgrounds
  /// Adds transparency and reduces saturation for a subtle effect
  static Color softenColor(Color color, {double opacity = 0.3}) {
    // Convert to HSL to reduce saturation
    final HSLColor hsl = HSLColor.fromColor(color);
    final softened = hsl.withSaturation((hsl.saturation * 0.7).clamp(0.0, 1.0));
    return softened.toColor().withValues(alpha: opacity);
  }

  /// Creates a blurred overlay color with adjustable intensity
  static Color blurOverlayColor(Color color, {double intensity = 0.4}) {
    return color.withValues(alpha: intensity);
  }

  /// Clears the color cache
  static void clearCache() {
    _colorCache.clear();
  }
}
