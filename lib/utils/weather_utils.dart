import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';

/// Centralized weather code handling utility
class WeatherUtils {
  /// Standard mapping of weather codes to human-readable descriptions
  static const Map<int, String> descriptions = {
    0: 'Clear sky',
    1: 'Mainly clear',
    2: 'Partly cloudy',
    3: 'Overcast',
    45: 'Foggy',
    48: 'Depositing rime fog',
    51: 'Light drizzle',
    53: 'Moderate drizzle',
    55: 'Dense drizzle',
    61: 'Slight rain',
    63: 'Moderate rain',
    65: 'Heavy rain',
    71: 'Slight snow',
    73: 'Moderate snow',
    75: 'Heavy snow',
    77: 'Snow grains',
    80: 'Slight rain showers',
    81: 'Moderate rain showers',
    82: 'Violent rain showers',
    85: 'Slight snow showers',
    86: 'Heavy snow showers',
    95: 'Thunderstorm',
    96: 'Thunderstorm with slight hail',
    99: 'Thunderstorm with heavy hail',
  };

  /// Default weather code to use when an invalid code is encountered
  static const int defaultWeatherCode = 0; // Clear sky

  /// Get a sanitized weather code (handles invalid codes)
  static int sanitizeWeatherCode(dynamic rawCode) {
    // First convert to int if needed
    int code;
    if (rawCode is int) {
      code = rawCode;
    } else {
      try {
        code = int.parse(rawCode.toString());
      } catch (e) {
        print('Invalid weather code format: $rawCode');
        return defaultWeatherCode;
      }
    }

    // Check if code is in our definitions
    if (!descriptions.containsKey(code)) {
      print('Unknown weather code: $code - using default');
      return defaultWeatherCode;
    }

    return code;
  }

  /// Get description for a weather code with fallback
  static String getDescription(int code) {
    return descriptions[code] ?? descriptions[defaultWeatherCode]!;
  }

  /// Build a weather icon that properly handles any weather code
  static Widget buildIcon(
      int code, DateTime? dateTime, double size, bool forceDay,
      [DateTime? sunrise, DateTime? sunset]) {
    // Sanitize the code first
    int safeCode = sanitizeWeatherCode(code);

    // Determine if it's night time
    final bool isNight = (!forceDay && dateTime != null)
        ? ((sunrise != null && sunset != null)
            ? (dateTime.hour < sunrise.hour || dateTime.hour > sunset.hour)
            : (dateTime.hour >= 18 || dateTime.hour < 6))
        : false;

    // Choose icon based on weather code
    switch (safeCode) {
      case 0:
        return BoxedIcon(
            isNight ? WeatherIcons.night_clear : WeatherIcons.day_sunny,
            size: size,
            color: isNight ? const Color(0xFF486581) : const Color(0xFFFF9D00));
      case 1:
      case 2:
        return BoxedIcon(
            isNight
                ? WeatherIcons.night_alt_partly_cloudy
                : WeatherIcons.day_cloudy_high,
            size: size,
            color: isNight ? const Color(0xFF486581) : const Color(0xFF62B2FF));
      case 3:
        return BoxedIcon(WeatherIcons.cloudy,
            size: size,
            color: isNight ? const Color(0xFF486581) : const Color(0xFF62B2FF));
      case 45:
      case 48:
        return BoxedIcon(WeatherIcons.fog,
            size: size,
            color: isNight ? const Color(0xFF7A8B9A) : const Color(0xFF9FB3C8));
      case 51:
        return BoxedIcon(WeatherIcons.sprinkle,
            size: size,
            color: isNight ? const Color(0xFF3178C6) : const Color(0xFF4098D7));
      case 53:
      case 55:
        return BoxedIcon(WeatherIcons.rain_mix,
            size: size,
            color: isNight ? const Color(0xFF3178C6) : const Color(0xFF4098D7));
      case 61:
      case 63:
      case 65:
        return BoxedIcon(WeatherIcons.rain,
            size: size,
            color: isNight ? const Color(0xFF25507A) : const Color(0xFF3178C6));
      case 71:
      case 73:
      case 75:
      case 77:
        return BoxedIcon(WeatherIcons.snow,
            size: size,
            color: isNight ? const Color(0xFF607D8B) : const Color(0xFF90CDF4));
      case 80:
      case 81:
        return BoxedIcon(WeatherIcons.showers,
            size: size,
            color: isNight ? const Color(0xFF1F3E5A) : const Color(0xFF3178C6));
      case 82:
        return BoxedIcon(WeatherIcons.storm_showers,
            size: size,
            color: isNight ? const Color(0xFF1F3E5A) : const Color(0xFF3178C6));
      case 85:
      case 86:
        return BoxedIcon(WeatherIcons.snow,
            size: size,
            color: isNight ? const Color(0xFF607D8B) : const Color(0xFF90CDF4));
      case 95:
      case 96:
      case 99:
        return BoxedIcon(WeatherIcons.thunderstorm,
            size: size,
            color: isNight ? const Color(0xFF553C7B) : const Color(0xFF4098D7));
      default:
        // This should never happen due to sanitization, but just in case
        return BoxedIcon(
            isNight ? WeatherIcons.night_clear : WeatherIcons.day_sunny,
            size: size,
            color: isNight ? const Color(0xFF486581) : const Color(0xFFFF9D00));
    }
  }
}
