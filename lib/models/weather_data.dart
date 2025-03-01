import 'package:flutter/material.dart';
import '../utils/weather_code_mapper.dart';
import 'dart:developer' as developer;

class WeatherData {
  final double temperature;
  final int weatherCode;
  final String weatherDescription;
  final IconData weatherIcon;
  // other weather properties...

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    String? description,
    IconData? icon,
    // other parameters...
  })  : weatherDescription =
            description ?? WeatherCodeMapper.getWeatherDescription(weatherCode),
        weatherIcon = icon ?? WeatherCodeMapper.getWeatherIcon(weatherCode);

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    // Log the incoming data to help with debugging
    developer.log('Weather API response: $json');

    // More robust extraction of weather code
    int? weatherCode;

    if (json.containsKey('weather_code')) {
      weatherCode = json['weather_code'];
    } else if (json.containsKey('current_weather') &&
        json['current_weather'] != null &&
        json['current_weather'].containsKey('weathercode')) {
      weatherCode = json['current_weather']['weathercode'];
    } else if (json.containsKey('current') &&
        json['current'] != null &&
        json['current'].containsKey('weather_code')) {
      weatherCode = json['current']['weather_code'];
    }

    // If no valid weather code was found, use -1 to represent unknown weather
    // instead of defaulting to 0 (clear sky)
    weatherCode = weatherCode ?? -1;

    // Temperature extraction with better null handling
    double temperature = 0.0;
    try {
      if (json.containsKey('temperature')) {
        temperature = (json['temperature'] is int)
            ? (json['temperature'] as int).toDouble()
            : json['temperature']?.toDouble() ?? 0.0;
      } else if (json.containsKey('current_weather') &&
          json['current_weather'] != null &&
          json['current_weather'].containsKey('temperature')) {
        temperature = (json['current_weather']['temperature'] is int)
            ? (json['current_weather']['temperature'] as int).toDouble()
            : json['current_weather']['temperature']?.toDouble() ?? 0.0;
      }
    } catch (e) {
      developer.log('Error parsing temperature: $e');
    }

    return WeatherData(
      temperature: temperature,
      weatherCode: weatherCode,
      // The description and icon will be automatically generated based on the weather code
      // other properties...
    );
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
