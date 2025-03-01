class AppLocation {
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String state;

  const AppLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.state,
  });

  String get displayName => name.isEmpty
      ? '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}'
      : country.isEmpty
          ? name
          : '$name, $country';

  factory AppLocation.fromJson(Map<String, dynamic> json) {
    return AppLocation(
      name: json['name'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      country: json['country'] ?? '',
      state: json['state'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'state': state,
    };
  }
}
