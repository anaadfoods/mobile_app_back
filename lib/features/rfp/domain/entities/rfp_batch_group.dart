/// A capacity group within an RFP batch.
class RfpBatchGroup {
  final int id;
  final String name;
  final int maxFamilies;
  final int bookedFamilyCount;
  final int slotsRemaining;
  final bool isFull;

  const RfpBatchGroup({
    required this.id,
    required this.name,
    required this.maxFamilies,
    required this.bookedFamilyCount,
    required this.slotsRemaining,
    required this.isFull,
  });
}
