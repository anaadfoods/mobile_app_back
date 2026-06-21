class Community {
  final int id;
  final String name;
  final String description;
  final String image;
  final String benefits;
  final bool comingSoon;
  final String? launchDate;

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
