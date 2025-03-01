import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart'; // Assuming you use this package

/// Utility class to map Open Meteo WMO weather codes to descriptions and icons
/// Based on documentation: https://open-meteo.com/en/docs/
class WeatherCodeMapper {
  /// Maps WMO weather codes to human-readable descriptions
  static String getWeatherDescription(int weatherCode) {
    // Special case for unknown weather
    if (weatherCode < 0) {
      return 'Weather data unavailable';
    }

    switch (weatherCode) {
      // Clear conditions
      case 0:
        return 'Clear sky';
      case 1:
        return 'Mainly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';

      // Fog and depositing rime fog
      case 45:
      case 48:
        return 'Fog';

      // Drizzle
      case 51:
        return 'Light drizzle';
      case 53:
        return 'Moderate drizzle';
      case 55:
        return 'Dense drizzle';
      case 56:
        return 'Light freezing drizzle';
      case 57:
        return 'Dense freezing drizzle';

      // Rain
      case 61:
        return 'Slight rain';
      case 63:
        return 'Moderate rain';
      case 65:
        return 'Heavy rain';
      case 66:
        return 'Light freezing rain';
      case 67:
        return 'Heavy freezing rain';

      // Snow
      case 71:
        return 'Slight snow fall';
      case 73:
        return 'Moderate snow fall';
      case 75:
        return 'Heavy snow fall';
      case 77:
        return 'Snow grains';

      // Rain showers
      case 80:
        return 'Slight rain showers';
      case 81:
        return 'Moderate rain showers';
      case 82:
        return 'Violent rain showers';

      // Snow showers & Thunderstorm
      case 85:
        return 'Slight snow showers';
      case 86:
        return 'Heavy snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';

      default:
        return 'Unknown weather ($weatherCode)'; // Include the code for debugging
    }
  }

  /// Maps WMO weather codes to appropriate weather icons
  static IconData getWeatherIcon(int weatherCode) {
    // Special case for unknown weather
    if (weatherCode < 0) {
      return WeatherIcons.na;
    }

    switch (weatherCode) {
      // Clear conditions
      case 0:
        return WeatherIcons.day_sunny;
      case 1:
        return WeatherIcons.day_sunny_overcast;
      case 2:
        return WeatherIcons.day_cloudy;
      case 3:
        return WeatherIcons.cloudy;

      // Fog
      case 45:
      case 48:
        return WeatherIcons.fog;

      // Drizzle
      case 51:
      case 53:
      case 55:
        return WeatherIcons.sprinkle;
      case 56:
      case 57:
        return WeatherIcons.sleet;

      // Rain
      case 61:
      case 63:
        return WeatherIcons.rain;
      case 65:
        return WeatherIcons.rain_wind;
      case 66:
      case 67:
        return WeatherIcons.sleet;

      // Snow
      case 71:
      case 73:
      case 75:
      case 77:
        return WeatherIcons.snow;

      // Rain showers
      case 80:
      case 81:
      case 82:
        return WeatherIcons.showers;

      // Snow showers
      case 85:
      case 86:
        return WeatherIcons.snow;

      // Thunderstorm
      case 95:
      case 96:
      case 99:
        return WeatherIcons.thunderstorm;

      default:
        return WeatherIcons.na; // Fallback for unexpected codes
    }
  }

  /// Optional: Get weather icon for night time based on weather code
  static IconData getWeatherIconNight(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return WeatherIcons.night_clear;
      case 1:
        return WeatherIcons.night_alt_partly_cloudy;
      case 2:
        return WeatherIcons.night_alt_cloudy;
      // Add more night-specific mappings as needed

      default:
        return getWeatherIcon(weatherCode); // Default to regular icons
    }
  }

  /// Optional: Get a color representing weather condition severity
  static Color getWeatherColor(int weatherCode) {
    if (weatherCode <= 3) {
      return Colors.blue; // Clear to cloudy
    } else if (weatherCode <= 48) {
      return Colors.grey; // Fog
    } else if (weatherCode <= 67) {
      return Colors.blueGrey; // Drizzle and rain
    } else if (weatherCode <= 77) {
      return Colors.lightBlue; // Snow
    } else if (weatherCode <= 82) {
      return Colors.indigoAccent; // Rain showers
    } else if (weatherCode <= 86) {
      return Colors.lightBlueAccent; // Snow showers
    } else {
      return Colors.deepPurple; // Thunderstorm
    }
  }
}
