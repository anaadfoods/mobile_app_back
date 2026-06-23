import 'package:grocery_app/services/api_config.dart';

class Community {
  final int id;
  final String name;
  final String description;
  final String image;
  final String benefits;
  final bool comingSoon;
  final String? launchDate;

  String get fullImageUrl {
    if (image.isEmpty) return '';
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }
    final cleanPath = image.startsWith('/') ? image : '/$image';
    return '${ApiConfig.baseUrl}$cleanPath';
  }

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.benefits,
    required this.comingSoon,
    this.launchDate,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      benefits: json['benefits'],
      comingSoon: json['coming_soon'],
      launchDate: json['launch_date'],
    );
  }
}
