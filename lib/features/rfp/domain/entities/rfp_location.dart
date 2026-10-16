/// Location where RFP service is available.
class RfpLocation {
  final String id;
  final String name;
  final String pincode;
  final String sector;
  final bool isActive;

  const RfpLocation({
    required this.id,
    required this.name,
    required this.pincode,
    required this.sector,
    required this.isActive,
  });
}
