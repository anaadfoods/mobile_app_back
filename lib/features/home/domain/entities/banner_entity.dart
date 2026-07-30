import 'package:equatable/equatable.dart';

class BannerEntity extends Equatable {
  final int id;
  final String title;
  final String subtitle;
  final String image;
  final String? link;
  final bool isActive;
  final String startDate;
  final String endDate;
  final int priority;

  const BannerEntity({
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

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        image,
        link,
        isActive,
        startDate,
        endDate,
        priority,
      ];
}
