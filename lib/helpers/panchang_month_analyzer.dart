import '../models/panchang/panchang_month_models.dart';

/// Analysis result for Indian month (masa) distribution in calendar grid
class MasaAnalysis {
  /// Which masa each row belongs to (rowIndex -> masa name)
  final Map<int, String> rowMasaMap;
  
  /// Row indices where masa transitions occur
  final List<int> transitionRows;
  
  /// List of unique masas present in this month
  final List<String> presentMasas;
  
  /// First masa in the month
  final String? firstMasa;
  
  /// Last masa in the month
  final String? lastMasa;

  const MasaAnalysis({
    required this.rowMasaMap,
    required this.transitionRows,
    required this.presentMasas,
    this.firstMasa,
    this.lastMasa,
  });
}

class PanchangMonthAnalyzer {
  /// Analyzes the calendar grid to determine masa distribution
  static MasaAnalysis analyzeMasaDistribution(
    List<List<PanchangDaySummary?>> grid,
  ) {
    if (grid.isEmpty) {
      return const MasaAnalysis(
        rowMasaMap: {},
        transitionRows: [],
        presentMasas: [],
      );
    }

    final rowMasaMap = <int, String>{};
    final transitionRows = <int>[];
    final presentMasasSet = <String>{};
    String? firstMasa;
    String? lastMasa;
    String? previousRowMasa;

    for (var rowIndex = 0; rowIndex < grid.length; rowIndex++) {
      final row = grid[rowIndex];
      
      // Find the dominant (most common) masa in this row
      final masaCounts = <String, int>{};
      for (final day in row) {
        if (day != null && day.masa.isNotEmpty) {
          masaCounts[day.masa] = (masaCounts[day.masa] ?? 0) + 1;
        }
      }

      if (masaCounts.isEmpty) continue;

      // Get the masa with highest count in this row
      final dominantMasa = masaCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      rowMasaMap[rowIndex] = dominantMasa;
      presentMasasSet.add(dominantMasa);

      // Track first and last masa
      firstMasa ??= dominantMasa;
      lastMasa = dominantMasa;

      // Detect transition (when masa changes from previous row)
      if (previousRowMasa != null && previousRowMasa != dominantMasa) {
        transitionRows.add(rowIndex);
      }

      previousRowMasa = dominantMasa;
    }

    return MasaAnalysis(
      rowMasaMap: rowMasaMap,
      transitionRows: transitionRows,
      presentMasas: presentMasasSet.toList(),
      firstMasa: firstMasa,
      lastMasa: lastMasa,
    );
  }

  /// Get the masa for a specific row index
  static String? getMasaForRow(MasaAnalysis analysis, int rowIndex) {
    return analysis.rowMasaMap[rowIndex];
  }

  /// Check if a row is a transition row
  static bool isTransitionRow(MasaAnalysis analysis, int rowIndex) {
    return analysis.transitionRows.contains(rowIndex);
  }

  /// Get the new masa that starts at a transition row
  static String? getNewMasaAtTransition(
    MasaAnalysis analysis,
    int rowIndex,
  ) {
    if (!isTransitionRow(analysis, rowIndex)) return null;
    return analysis.rowMasaMap[rowIndex];
  }
}
