import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Indian lunar month information
class IndianMonth {
  final int index;
  final String sanskritName;
  final String hindiName;
  final String gregorianPeriod;
  final Color color;
  final Color lightColor;
  final Color darkColor;

  const IndianMonth({
    required this.index,
    required this.sanskritName,
    required this.hindiName,
    required this.gregorianPeriod,
    required this.color,
    required this.lightColor,
    required this.darkColor,
  });

  String get abbreviation => sanskritName.substring(0, 3).toUpperCase();
}

class IndianMonthHelper {
  static const List<IndianMonth> months = [
    IndianMonth(
      index: 1,
      sanskritName: 'Chaitra',
      hindiName: 'Chait',
      gregorianPeriod: 'March – April',
      color: AppColors.deepSoilGreen,
      lightColor: Color(0xFF235A27),
      darkColor: Color(0xFF81C784),
    ),
    IndianMonth(
      index: 2,
      sanskritName: 'Vaishakha',
      hindiName: 'Baisakh',
      gregorianPeriod: 'April – May',
      color: AppColors.harvestAmber,
      lightColor: Color(0xFFB76400),
      darkColor: Color(0xFFFFB74D),
    ),
    IndianMonth(
      index: 3,
      sanskritName: 'Jyeshtha',
      hindiName: 'Jeth',
      gregorianPeriod: 'May – June',
      color: AppColors.rawEarth,
      lightColor: Color(0xFF9E3D07),
      darkColor: Color(0xFFFF8A65),
    ),
    IndianMonth(
      index: 4,
      sanskritName: 'Ashadha',
      hindiName: 'Ashadh',
      gregorianPeriod: 'June – July',
      color: Color(0xFF0E7A68),
      lightColor: Color(0xFF0E7A68),
      darkColor: Color(0xFF4DB6AC),
    ),
    IndianMonth(
      index: 5,
      sanskritName: 'Shravana',
      hindiName: 'Sawan',
      gregorianPeriod: 'July – August',
      color: Color(0xFF1B7A38),
      lightColor: Color(0xFF1B7A38),
      darkColor: Color(0xFF66BB6A),
    ),
    IndianMonth(
      index: 6,
      sanskritName: 'Bhadrapada',
      hindiName: 'Bhado',
      gregorianPeriod: 'August – September',
      color: Color(0xFFC07000),
      lightColor: Color(0xFFC07000),
      darkColor: Color(0xFFFFCA28),
    ),
    IndianMonth(
      index: 7,
      sanskritName: 'Ashvina',
      hindiName: 'Ashwin',
      gregorianPeriod: 'September – October',
      color: Color(0xFF6A3B8B),
      lightColor: Color(0xFF6A3B8B),
      darkColor: Color(0xFFBA68C8),
    ),
    IndianMonth(
      index: 8,
      sanskritName: 'Kartika',
      hindiName: 'Kartik',
      gregorianPeriod: 'October – November',
      color: Color(0xFFA07800),
      lightColor: Color(0xFFA07800),
      darkColor: Color(0xFFFFD54F),
    ),
    IndianMonth(
      index: 9,
      sanskritName: 'Margashirsha',
      hindiName: 'Agahan',
      gregorianPeriod: 'November – December',
      color: Color(0xFF10705E),
      lightColor: Color(0xFF10705E),
      darkColor: Color(0xFF80CBC4),
    ),
    IndianMonth(
      index: 10,
      sanskritName: 'Pausha',
      hindiName: 'Poos',
      gregorianPeriod: 'December – January',
      color: Color(0xFF1A6B9B),
      lightColor: Color(0xFF1A6B9B),
      darkColor: Color(0xFF64B5F6),
    ),
    IndianMonth(
      index: 11,
      sanskritName: 'Magha',
      hindiName: 'Magh',
      gregorianPeriod: 'January – February',
      color: Color(0xFFB55A20),
      lightColor: Color(0xFFB55A20),
      darkColor: Color(0xFFFFAB91),
    ),
    IndianMonth(
      index: 12,
      sanskritName: 'Phalguna',
      hindiName: 'Phagun',
      gregorianPeriod: 'February – March',
      color: Color(0xFF9E2A2B),
      lightColor: Color(0xFF9E2A2B),
      darkColor: Color(0xFFEF9A9A),
    ),
  ];

  /// Get Indian month by index (1-12)
  static IndianMonth? getByIndex(int index) {
    try {
      return months.firstWhere((m) => m.index == index);
    } catch (e) {
      return null;
    }
  }

  /// Get Indian month by Sanskrit name (case-insensitive)
  static IndianMonth? getBySanskritName(String name) {
    if (name.isEmpty) return null;
    try {
      return months.firstWhere(
        (m) => m.sanskritName.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get Indian month by Hindi name
  static IndianMonth? getByHindiName(String name) {
    if (name.isEmpty) return null;
    try {
      return months.firstWhere(
        (m) => m.hindiName.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get color for a masa name (tries to match by name)
  static Color getColorForMasa(
    String masaName,
    bool isDark, {
    double opacity = 0.12,
  }) {
    final month = getBySanskritName(masaName) ?? getByHindiName(masaName);
    if (month == null) {
      // Default fallback color
      return (isDark ? AppColors.parchment : AppColors.parchment).withValues(
        alpha: opacity,
      );
    }
    return (isDark ? month.darkColor : month.lightColor).withValues(
      alpha: opacity,
    );
  }

  /// Get base color (without opacity) for masa
  static Color getBaseColorForMasa(String masaName, bool isDark) {
    final month = getBySanskritName(masaName) ?? getByHindiName(masaName);
    if (month == null) {
      return isDark ? AppColors.parchment : AppColors.parchment;
    }
    return isDark ? month.darkColor : month.lightColor;
  }

  /// Get all Indian months that might appear in a given Gregorian month
  static List<IndianMonth> getMonthsForGregorianMonth(int gregorianMonth) {
    switch (gregorianMonth) {
      case 1: // January
        return [getByIndex(10)!, getByIndex(11)!]; // Pausha, Magha
      case 2: // February
        return [getByIndex(11)!, getByIndex(12)!]; // Magha, Phalguna
      case 3: // March
        return [getByIndex(12)!, getByIndex(1)!]; // Phalguna, Chaitra
      case 4: // April
        return [getByIndex(1)!, getByIndex(2)!]; // Chaitra, Vaishakha
      case 5: // May
        return [getByIndex(2)!, getByIndex(3)!]; // Vaishakha, Jyeshtha
      case 6: // June
        return [getByIndex(3)!, getByIndex(4)!]; // Jyeshtha, Ashadha
      case 7: // July
        return [getByIndex(4)!, getByIndex(5)!]; // Ashadha, Shravana
      case 8: // August
        return [getByIndex(5)!, getByIndex(6)!]; // Shravana, Bhadrapada
      case 9: // September
        return [getByIndex(6)!, getByIndex(7)!]; // Bhadrapada, Ashvina
      case 10: // October
        return [getByIndex(7)!, getByIndex(8)!]; // Ashvina, Kartika
      case 11: // November
        return [getByIndex(8)!, getByIndex(9)!]; // Kartika, Margashirsha
      case 12: // December
        return [getByIndex(9)!, getByIndex(10)!]; // Margashirsha, Pausha
      default:
        return [];
    }
  }
}
