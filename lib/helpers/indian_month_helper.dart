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
      color: Color(0xFFFF9066),
      lightColor: Color(0xFFFFDCC2),
      darkColor: Color(0xFFFF6B35),
    ),
    IndianMonth(
      index: 2,
      sanskritName: 'Vaishakha',
      hindiName: 'Baisakh',
      gregorianPeriod: 'April – May',
      color: Color(0xFF66D9A6),
      lightColor: Color(0xFFC2F5DD),
      darkColor: Color(0xFF35B87A),
    ),
    IndianMonth(
      index: 3,
      sanskritName: 'Jyeshtha',
      hindiName: 'Jeth',
      gregorianPeriod: 'May – June',
      color: Color(0xFF66C2FF),
      lightColor: Color(0xFFC2E8FF),
      darkColor: Color(0xFF3597D9),
    ),
    IndianMonth(
      index: 4,
      sanskritName: 'Ashadha',
      hindiName: 'Ashadh',
      gregorianPeriod: 'June – July',
      color: Color(0xFF66D9CC),
      lightColor: Color(0xFFC2F5F0),
      darkColor: Color(0xFF35B8AA),
    ),
    IndianMonth(
      index: 5,
      sanskritName: 'Shravana',
      hindiName: 'Sawan',
      gregorianPeriod: 'July – August',
      color: Color(0xFF9966FF),
      lightColor: Color(0xFFDCC2FF),
      darkColor: Color(0xFF7035D9),
    ),
    IndianMonth(
      index: 6,
      sanskritName: 'Bhadrapada',
      hindiName: 'Bhado',
      gregorianPeriod: 'August – September',
      color: Color(0xFFFFCC66),
      lightColor: Color(0xFFFFF0C2),
      darkColor: Color(0xFFD9A835),
    ),
    IndianMonth(
      index: 7,
      sanskritName: 'Ashvina',
      hindiName: 'Ashwin',
      gregorianPeriod: 'September – October',
      color: Color(0xFFFF66A3),
      lightColor: Color(0xFFFFB8D6),
      darkColor: Color(0xFFD93575),
    ),
    IndianMonth(
      index: 8,
      sanskritName: 'Kartika',
      hindiName: 'Kartik',
      gregorianPeriod: 'October – November',
      color: Color(0xFFFF8C66),
      lightColor: Color(0xFFFFD4C2),
      darkColor: Color(0xFFD96235),
    ),
    IndianMonth(
      index: 9,
      sanskritName: 'Margashirsha',
      hindiName: 'Agahan',
      gregorianPeriod: 'November – December',
      color: Color(0xFF66FFB8),
      lightColor: Color(0xFFC2FFE3),
      darkColor: Color(0xFF35D98C),
    ),
    IndianMonth(
      index: 10,
      sanskritName: 'Pausha',
      hindiName: 'Poos',
      gregorianPeriod: 'December – January',
      color: Color(0xFF66E0FF),
      lightColor: Color(0xFFC2F5FF),
      darkColor: Color(0xFF35BBD9),
    ),
    IndianMonth(
      index: 11,
      sanskritName: 'Magha',
      hindiName: 'Magh',
      gregorianPeriod: 'January – February',
      color: Color(0xFFB366FF),
      lightColor: Color(0xFFE3C2FF),
      darkColor: Color(0xFF8935D9),
    ),
    IndianMonth(
      index: 12,
      sanskritName: 'Phalguna',
      hindiName: 'Phagun',
      gregorianPeriod: 'February – March',
      color: Color(0xFFFFB366),
      lightColor: Color(0xFFFFE3C2),
      darkColor: Color(0xFFD98935),
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
  static Color getColorForMasa(String masaName, bool isDark, {double opacity = 0.12}) {
    final month = getBySanskritName(masaName) ?? getByHindiName(masaName);
    if (month == null) {
      // Default fallback color
      return (isDark ? const Color(0xFF6B4EFF) : const Color(0xFFB4A0FF))
          .withOpacity(opacity);
    }
    return (isDark ? month.darkColor : month.lightColor).withOpacity(opacity);
  }

  /// Get base color (without opacity) for masa
  static Color getBaseColorForMasa(String masaName, bool isDark) {
    final month = getBySanskritName(masaName) ?? getByHindiName(masaName);
    if (month == null) {
      return isDark ? const Color(0xFF6B4EFF) : const Color(0xFFB4A0FF);
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
