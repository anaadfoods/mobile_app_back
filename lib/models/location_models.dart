// models/location_models.dart
class StateModel {
  final int id;
  final String name;
  final String? iso2;

  StateModel({required this.id, required this.name, this.iso2});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id'],
      name: json['name'] ?? '',
      iso2: json['iso2'],
    );
  }

  @override
  String toString() => name;
}

class CityModel {
  final int id;
  final String name;

  CityModel({required this.id, required this.name});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }

  @override
  String toString() => name;
}
