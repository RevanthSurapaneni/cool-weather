import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  static const String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  static Future<List<Location>> geocodeLocation(String query) async {
    final response = await http.get(Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$query&count=10&language=en'));
    if (response.statusCode == 200) {
      final results = jsonDecode(response.body)['results'] as List?;
      if (results == null || results.isEmpty) {
        throw Exception('No locations found');
      }
      return results.map((e) => Location.fromJson(e)).toList();
    } else {
      throw Exception('Failed to geocode location');
    }
  }

  static Future<List<Location>> reverseGeocodeLocation(
      double lat, double lon) async {
    final response = await http.get(Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/reverse?latitude=$lat&longitude=$lon&language=en&count=1'));
    if (response.statusCode == 200) {
      final results = jsonDecode(response.body)['results'] as List?;
      if (results == null || results.isEmpty) {
        return [];
      }
      return results.map((e) => Location.fromJson(e)).toList();
    } else {
      throw Exception('Failed to reverse geocode location');
    }
  }

  static Future<AirQualityData> getAirQuality(double lat, double lon) async {
    final response = await http.get(Uri.parse(
        'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon&hourly=pm2_5,pm10,carbon_monoxide,sulphur_dioxide,ozone,nitrogen_dioxide&timezone=auto'));

    if (response.statusCode == 200) {
      print('Air Quality API Response: ${response.body}'); // Log the response
      return AirQualityData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load air quality data');
    }
  }

  static Future<WeatherData> getWeather(double lat, double lon) async {
    final response = await http.get(Uri.parse(
        '$baseUrl?latitude=$lat&longitude=$lon'
        '&current_weather=true'
        '&hourly=temperature_2m,weathercode,precipitation_probability,apparent_temperature,wind_speed_10m,wind_direction_10m,uv_index,is_day'
        '&daily=weathercode,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max,wind_speed_10m_max'
        '&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch'
        '&timezone=auto'));
    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}

class Location {
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String? state;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    this.state,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      country: json['country'] ?? '',
      state: json['admin1'],
    );
  }

  String get displayName {
    return (state != null && state!.isNotEmpty)
        ? '$name, $state, $country'
        : '$name, $country';
  }
}

class WeatherData {
  final double currentTemp;
  final double currentWindSpeed;
  final int currentWeatherCode;
  final Map<String, dynamic> hourly;
  final Map<String, dynamic> daily;
  final DateTime sunrise;
  final DateTime sunset;
  final double uvIndex;
  final double feelsLike;
  final int windDirection;
  final bool isDay;
  final DateTime currentWeatherTime;
  AirQualityData? airQualityData;

  WeatherData({
    required this.currentTemp,
    required this.currentWindSpeed,
    required this.currentWeatherCode,
    required this.hourly,
    required this.daily,
    required this.sunrise,
    required this.sunset,
    required this.uvIndex,
    required this.feelsLike,
    required this.windDirection,
    required this.isDay,
    required this.currentWeatherTime,
    this.airQualityData,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final todayIndex = 0;
    final List<String> hourlyTime = List<String>.from(json['hourly']['time']);
    final currentHourString =
        DateTime(now.year, now.month, now.day, now.hour).toIso8601String();
    final currentIndex = hourlyTime.indexWhere((time) {
      final forecastTime = DateTime.parse(time);
      return forecastTime.year == now.year &&
          forecastTime.month == now.month &&
          forecastTime.day == now.day &&
          forecastTime.hour == now.hour;
    });

    try {
      return WeatherData(
        currentTemp: (json['current_weather']['temperature'] as num).toDouble(),
        currentWindSpeed:
            (json['current_weather']['windspeed'] as num).toDouble(),
        currentWeatherCode: json['current_weather']['weathercode'] as int,
        hourly: json['hourly'] as Map<String, dynamic>,
        daily: json['daily'] as Map<String, dynamic>,
        sunrise: DateTime.parse(json['daily']['sunrise'][todayIndex]),
        sunset: DateTime.parse(json['daily']['sunset'][todayIndex]),
        uvIndex: currentIndex != -1
            ? (json['hourly']['uv_index'][currentIndex] ?? 0).toDouble()
            : 0.0,
        feelsLike: currentIndex != -1
            ? (json['hourly']['apparent_temperature'][currentIndex] ??
                    json['current_weather']['temperature'])
                .toDouble()
            : (json['current_weather']['temperature'] as num).toDouble(),
        windDirection: json['current_weather']['winddirection'] as int,
        isDay: currentIndex != -1
            ? (json['hourly']['is_day'][currentIndex] ?? 1) == 1
            : true,
        currentWeatherTime: DateTime.parse(json['current_weather']['time']),
      );
    } catch (e) {
      throw Exception('Failed to parse weather data: $e');
    }
  }

  // Added wind direction method
  String getWindDirection() {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return directions[((windDirection + 22.5) % 360) ~/ 45];
  }
}

class AirQualityData {
  final double pm2_5;
  final double pm10;
  final double carbon_monoxide;
  final double sulphur_dioxide;
  final double ozone;
  final double nitrogen_dioxide;
  final DateTime time;

  AirQualityData({
    required this.pm2_5,
    required this.pm10,
    required this.carbon_monoxide,
    required this.sulphur_dioxide,
    required this.ozone,
    required this.nitrogen_dioxide,
    required this.time,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> timeList = json['hourly']['time'];
    final now = DateTime.now();
    final currentHourString =
        DateTime(now.year, now.month, now.day, now.hour).toIso8601String();
    final currentIndex = timeList.indexWhere((time) {
      final forecastTime = DateTime.parse(time);
      return forecastTime.year == now.year &&
          forecastTime.month == now.month &&
          forecastTime.day == now.day &&
          forecastTime.hour == now.hour;
    });

    // Fallback to the first available time if the current time is not found
    final fallbackIndex = currentIndex != -1 ? currentIndex : 0;

    // Check if currentIndex is valid before accessing the lists
    final pm2_5List = json['hourly']['pm2_5'] as List<dynamic>?;
    final pm10List = json['hourly']['pm10'] as List<dynamic>?;
    final carbon_monoxideList =
        json['hourly']['carbon_monoxide'] as List<dynamic>?;
    final sulphur_dioxideList =
        json['hourly']['sulphur_dioxide'] as List<dynamic>?;
    final ozoneList = json['hourly']['ozone'] as List<dynamic>?;
    final nitrogen_dioxideList =
        json['hourly']['nitrogen_dioxide'] as List<dynamic>?;

    print('PM2.5 List: $pm2_5List'); // Log the PM2.5 list
    print('Current Index: $currentIndex'); // Log the current index

    final pm2_5 = (pm2_5List != null &&
            fallbackIndex != -1 &&
            fallbackIndex < pm2_5List.length)
        ? (pm2_5List[fallbackIndex] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final pm10 = (pm10List != null &&
            fallbackIndex != -1 &&
            fallbackIndex < pm10List.length)
        ? (pm10List[fallbackIndex] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final carbon_monoxide = (carbon_monoxideList != null &&
            fallbackIndex != -1 &&
            fallbackIndex < carbon_monoxideList.length)
        ? (carbon_monoxideList[fallbackIndex] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final sulphur_dioxide = (sulphur_dioxideList != null &&
            fallbackIndex != -1 &&
            fallbackIndex < sulphur_dioxideList.length)
        ? (sulphur_dioxideList[fallbackIndex] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final ozone = (ozoneList != null &&
            fallbackIndex != -1 &&
            fallbackIndex < ozoneList.length)
        ? (ozoneList[fallbackIndex] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final nitrogen_dioxide = (nitrogen_dioxideList != null &&
            fallbackIndex != -1 &&
            fallbackIndex < nitrogen_dioxideList.length)
        ? (nitrogen_dioxideList[fallbackIndex] as num?)?.toDouble() ?? 0.0
        : 0.0;

    return AirQualityData(
      pm2_5: pm2_5,
      pm10: pm10,
      carbon_monoxide: carbon_monoxide,
      sulphur_dioxide: sulphur_dioxide,
      ozone: ozone,
      nitrogen_dioxide: nitrogen_dioxide,
      time: (fallbackIndex != -1 && timeList.length > fallbackIndex)
          ? DateTime.parse(timeList[fallbackIndex])
          : DateTime.now(),
    );
  }
}
