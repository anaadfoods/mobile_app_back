class BannerModel {
  final int id;
  final String title;
  final String subtitle;
  final String image;
  final String? link;
  final bool isActive;
  final String startDate;
  final String endDate;
  final int priority;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    this.link,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    required this.priority,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      image: json['image'] ?? '',
      link: json['link'],
      isActive: json['is_active'] ?? false,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      priority: json['priority'] ?? 0,
    );
  }
}
