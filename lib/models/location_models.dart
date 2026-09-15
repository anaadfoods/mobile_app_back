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
    return CityModel(id: json['id'], name: json['name'] ?? '');
  }

  @override
  String toString() => name;
}

/// Represents a location search suggestion from Google Places or OpenStreetMap
class LocationSuggestion {
  final String placeId;
  final String displayName;
  final String mainText;
  final String secondaryText;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? raw;

  const LocationSuggestion({
    required this.placeId,
    required this.displayName,
    required this.mainText,
    required this.secondaryText,
    this.city = '',
    this.state = '',
    this.country = 'India',
    this.pincode = '',
    this.latitude,
    this.longitude,
    this.raw,
  });

  LocationSuggestion copyWith({
    String? placeId,
    String? displayName,
    String? mainText,
    String? secondaryText,
    String? city,
    String? state,
    String? country,
    String? pincode,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? raw,
  }) {
    return LocationSuggestion(
      placeId: placeId ?? this.placeId,
      displayName: displayName ?? this.displayName,
      mainText: mainText ?? this.mainText,
      secondaryText: secondaryText ?? this.secondaryText,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      raw: raw ?? this.raw,
    );
  }

  /// Parses OpenStreetMap Nominatim JSON object
  factory LocationSuggestion.fromOpenStreetMap(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    final displayName = json['display_name'] as String? ?? '';

    // Extract city / town / village
    final city = address['city'] ??
        address['town'] ??
        address['village'] ??
        address['municipality'] ??
        address['county'] ??
        address['state_district'] ??
        '';

    final state = address['state'] as String? ?? '';
    final country = address['country'] as String? ?? 'India';
    final pincode = address['postcode'] as String? ?? '';

    final name = json['name'] as String? ?? '';
    final mainText = name.isNotEmpty
        ? name
        : (city.isNotEmpty ? city : displayName.split(',').first.trim());

    final secondaryParts = <String>[];
    if (state.isNotEmpty && state != mainText) secondaryParts.add(state);
    if (country.isNotEmpty && country != mainText) secondaryParts.add(country);
    final secondaryText =
        secondaryParts.isNotEmpty ? secondaryParts.join(', ') : displayName;

    final lat = double.tryParse(json['lat']?.toString() ?? '');
    final lon = double.tryParse(json['lon']?.toString() ?? '');

    return LocationSuggestion(
      placeId: json['place_id']?.toString() ?? '',
      displayName: displayName,
      mainText: mainText,
      secondaryText: secondaryText,
      city: city.isNotEmpty ? city : mainText,
      state: state,
      country: country,
      pincode: pincode,
      latitude: lat,
      longitude: lon,
      raw: json,
    );
  }

  /// Parses Google Places Autocomplete prediction JSON object
  factory LocationSuggestion.fromGooglePlaces(Map<String, dynamic> json) {
    final structured =
        json['structured_formatting'] as Map<String, dynamic>? ?? {};
    final mainText =
        structured['main_text'] as String? ?? json['description'] ?? '';
    final secondaryText = structured['secondary_text'] as String? ?? '';
    final description = json['description'] as String? ?? mainText;

    return LocationSuggestion(
      placeId: json['place_id'] as String? ?? '',
      displayName: description,
      mainText: mainText,
      secondaryText: secondaryText,
      city: mainText,
      raw: json,
    );
  }

  @override
  String toString() => displayName;
}
