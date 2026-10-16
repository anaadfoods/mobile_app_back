import 'rfp_vegetable.dart';

/// A farm patch within a batch (P1, P2, P3, P4).
class RfpPatch {
  final String id;
  final String label; // 'P1', 'P2', etc.
  final String name; // 'Agricultural Box', 'Organic Greens', etc.
  final List<RfpVegetable> vegetables;
  final int maxExclusions;
  final List<double> availableWeights; // e.g. [2.5, 5.0, 7.5]
  final double startingPrice;
  final String? imageUrl;

  const RfpPatch({
    required this.id,
    required this.label,
    required this.name,
    required this.vegetables,
    required this.maxExclusions,
    required this.availableWeights,
    required this.startingPrice,
    this.imageUrl,
  });

  int get vegetableCount => vegetables.length;
}
