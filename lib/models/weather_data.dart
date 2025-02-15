class WeatherData {
  final Map<String, dynamic> hourly;
  final Map<String, dynamic> daily;
  final DateTime currentWeatherTime;
  final int currentWeatherCode;
  final double currentTemp;
  final double currentWindSpeed;
  final double uvIndex;
  final DateTime sunrise;
  final DateTime sunset;
  AirQualityData? airQualityData;

  WeatherData({
    required this.hourly,
    required this.daily,
    required this.currentWeatherTime,
    required this.currentWeatherCode,
    required this.currentTemp,
    required this.currentWindSpeed,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
    this.airQualityData,
  });

  String getWindDirection() {
    // Dummy implementation – replace with your logic if needed
    return "N";
  }
}

class AirQualityData {
  final double pm2_5;
  AirQualityData({required this.pm2_5});
}

class Location {
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String state;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.state,
  });

  String get displayName => name;
}
