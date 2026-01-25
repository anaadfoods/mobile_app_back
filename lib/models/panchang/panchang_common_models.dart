class PanchangLocation {
  final String label;
  final double? latitude;
  final double? longitude;

  const PanchangLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  factory PanchangLocation.fromJson(Map<String, dynamic> json) {
    return PanchangLocation(
      label: (json['label'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class PanchangFestivalItem {
  final String name;
  final String? nameEn;
  final String? nameHi;
  final String type;
  final String source;
  final String? code;

  const PanchangFestivalItem({
    required this.name,
    required this.type,
    required this.source,
    this.nameEn,
    this.nameHi,
    this.code,
  });

  factory PanchangFestivalItem.fromJson(Map<String, dynamic> json) {
    return PanchangFestivalItem(
      name: (json['name'] ?? '').toString(),
      nameEn: json['name_en']?.toString(),
      nameHi: json['name_hi']?.toString(),
      type: (json['type'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      code: json['code']?.toString(),
    );
  }
}
