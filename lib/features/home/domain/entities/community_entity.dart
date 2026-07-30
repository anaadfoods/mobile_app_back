import 'package:equatable/equatable.dart';

class CommunityEntity extends Equatable {
  final int id;
  final String name;
  final String description;
  final String image;
  final String benefits;
  final bool comingSoon;
  final String? launchDate;
  final String fullImageUrl;

  const CommunityEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.benefits,
    required this.comingSoon,
    this.launchDate,
    required this.fullImageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        image,
        benefits,
        comingSoon,
        launchDate,
        fullImageUrl,
      ];
}
