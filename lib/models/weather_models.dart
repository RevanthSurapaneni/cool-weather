// Minimal model definitions for missing types
class Location {
  final String displayName; // using displayName as provided text
  final double latitude;
  final double longitude;
  final String country;
  final String state;

  Location({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.country = '',
    this.state = '',
  });
}

class AirQualityData {
  final double pm2_5;
  AirQualityData({required this.pm2_5});
}

class WeatherData {
  final int currentWeatherCode;
  final DateTime currentWeatherTime;
  final double currentTemp;
  final double currentWindSpeed;
  final double uvIndex;
  final DateTime sunrise;
  final DateTime sunset;
  final Map<String, dynamic> hourly;
  final Map<String, dynamic> daily;

  AirQualityData? airQualityData;

  WeatherData({
    required this.currentWeatherCode,
    required this.currentWeatherTime,
    required this.currentTemp,
    required this.currentWindSpeed,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
    required this.hourly,
    required this.daily,
  });

  String getWindDirection() {
    // Stub implementation, return a dummy direction.
    return 'N';
  }
}
