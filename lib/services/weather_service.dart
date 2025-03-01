import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/weather_utils.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _geocodingBaseUrl =
      'https://geocoding-api.open-meteo.com/v1/search';
  static const String _weatherBaseUrl =
      'https://api.open-meteo.com/v1/forecast';
  static const String _airQualityBaseUrl =
      'https://air-quality-api.open-meteo.com/v1/air-quality';

  final String apiKey;
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  WeatherService({required this.apiKey});

  // CORS handling for web platform
  static String _getUrl(String baseUrl, Map<String, String> params) {
    if (kIsWeb) {
      final Uri uri = Uri.parse(baseUrl).replace(queryParameters: params);
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(uri.toString())}';
    }
    return Uri.parse(baseUrl).replace(queryParameters: params).toString();
  }

  static Future<List<Location>> geocodeLocation(String query) async {
    final params = {
      'name': query,
      'count': '10',
      'language': 'en',
    };

    try {
      final url = _getUrl(_geocodingBaseUrl, params);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final List? results = data['results'] as List?;

        if (results == null || results.isEmpty) {
          return [];
        }

        return results
            .map((e) => Location.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to geocode location: $e');
    }
  }

  static Future<List<Location>> reverseGeocodeLocation(
      double lat, double lon) async {
    try {
      final response = await http.get(Uri.parse(
          '$_geocodingBaseUrl?latitude=$lat&longitude=$lon&language=en&count=1'));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final List? results = data['results'] as List?;

        if (results == null || results.isEmpty) {
          return [];
        }

        return results
            .map((e) => Location.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to reverse geocode: $e');
    }
  }

  static Future<AirQualityData> getAirQuality(double lat, double lon) async {
    final params = {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'hourly':
          'pm2_5,pm10,carbon_monoxide,sulphur_dioxide,ozone,nitrogen_dioxide,us_aqi',
      'timezone': 'auto',
    };

    try {
      final url = _getUrl(_airQualityBaseUrl, params);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return AirQualityData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load air quality data: $e');
    }
  }

  static Future<WeatherData> getWeather(double lat, double lon,
      {bool useMetric = false}) async {
    final params = {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'current_weather': 'true',
      'hourly': 'temperature_2m,weathercode,precipitation_probability,'
          'apparent_temperature,wind_speed_10m,wind_direction_10m,'
          'uv_index,is_day,relative_humidity_2m,precipitation,cloud_cover,'
          'visibility',
      'daily': 'weathercode,temperature_2m_max,temperature_2m_min,sunrise,'
          'sunset,uv_index_max,precipitation_probability_max,wind_speed_10m_max',
      'timezone': 'auto',
      'temperature_unit': useMetric ? 'celsius' : 'fahrenheit',
      'windspeed_unit': useMetric ? 'kmh' : 'mph',
      'precipitation_unit': useMetric ? 'mm' : 'inch',
      // Decrease forecast days from 16 to 15 to avoid potential array bound issues
      'forecast_days': '15',
    };

    try {
      final url = _getUrl(_weatherBaseUrl, params);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return WeatherData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load weather data: $e');
    }
  }

  Future<WeatherModel> getWeatherByCity(String city) async {
    final url = '$baseUrl?q=$city&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<WeatherModel> getWeatherByLocation(double lat, double lon) async {
    final url = '$baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
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
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: json['country'] ?? '',
      state: json['admin1'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'admin1': state,
    };
  }

  String get displayName {
    if (state != null && state!.isNotEmpty) {
      return '$name, $state, $country';
    }
    return country.isNotEmpty ? '$name, $country' : name;
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
      // Sanitize the weather code immediately when parsing
      final dynamic rawCode = json['current_weather']['weathercode'];
      final int safeWeatherCode = WeatherUtils.sanitizeWeatherCode(rawCode);

      return WeatherData(
        currentTemp: (json['current_weather']['temperature'] as num).toDouble(),
        currentWindSpeed:
            (json['current_weather']['windspeed'] as num).toDouble(),
        currentWeatherCode: safeWeatherCode, // Use sanitized code
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
  final int europeanAQI;
  final int usAQI; // Add US AQI field
  final DateTime time;

  AirQualityData({
    required this.pm2_5,
    required this.pm10,
    required this.carbon_monoxide,
    required this.sulphur_dioxide,
    required this.ozone,
    required this.nitrogen_dioxide,
    required this.europeanAQI,
    required this.usAQI, // Add US AQI parameter
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
    final carbonMonoxidelist =
        json['hourly']['carbon_monoxide'] as List<dynamic>?;
    final sulphurDioxidelist =
        json['hourly']['sulphur_dioxide'] as List<dynamic>?;
    final ozoneList = json['hourly']['ozone'] as List<dynamic>?;
    final nitrogenDioxidelist =
        json['hourly']['nitrogen_dioxide'] as List<dynamic>?;
    final europeanAQIList = json['hourly']['european_aqi'] as List<dynamic>?;
    final usAQIList = json['hourly']['us_aqi'] as List<dynamic>?;

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
    final carbonMonoxide = (carbonMonoxidelist != null &&
            fallbackIndex != -1 &&
            fallbackIndex < carbonMonoxidelist.length)
        ? (carbonMonoxidelist[fallbackIndex] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final sulphurDioxide = (sulphurDioxidelist != null &&
            fallbackIndex != -1 &&
            fallbackIndex < sulphurDioxidelist.length)
        ? (sulphurDioxidelist[fallbackIndex] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final ozone = (ozoneList != null &&
            fallbackIndex != -1 &&
            fallbackIndex < ozoneList.length)
        ? (ozoneList[fallbackIndex] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final nitrogenDioxide = (nitrogenDioxidelist != null &&
            fallbackIndex != -1 &&
            fallbackIndex < nitrogenDioxidelist.length)
        ? (nitrogenDioxidelist[fallbackIndex] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final europeanAQI = (europeanAQIList != null &&
            fallbackIndex != -1 &&
            fallbackIndex < europeanAQIList.length)
        ? europeanAQIList[fallbackIndex] as int
        : 0;
    final usAQI = (usAQIList != null &&
            fallbackIndex != -1 &&
            fallbackIndex < usAQIList.length)
        ? usAQIList[fallbackIndex] as int
        : 0;

    return AirQualityData(
      pm2_5: pm2_5,
      pm10: pm10,
      carbon_monoxide: carbonMonoxide,
      sulphur_dioxide: sulphurDioxide,
      ozone: ozone,
      nitrogen_dioxide: nitrogenDioxide,
      europeanAQI: europeanAQI,
      usAQI: usAQI,
      time: (fallbackIndex != -1 && timeList.length > fallbackIndex)
          ? DateTime.parse(timeList[fallbackIndex])
          : DateTime.now(),
    );
  }
}
