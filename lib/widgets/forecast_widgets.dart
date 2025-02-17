import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' show min;
import 'package:weather_icons/weather_icons.dart';
import '../services/weather_service.dart';
import '../utils/custom_scroll_behavior.dart';
import 'air_quality_widget.dart'; 

const Map<int, String> weatherDescriptions = {
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

Widget buildHourlyForecast(
    Map<String, dynamic> hourly,
    DateTime currentWeatherTime,
    DateTime sunrise,
    DateTime sunset,
    ScrollController controller,
    bool useMetric) {
  return Builder(
    builder: (context) {
      final List<String> times = List<String>.from(hourly['time']);
      final List<dynamic> temps = hourly['temperature_2m'];
      final List<dynamic> codes = hourly['weathercode'];
      final List<dynamic>? precipitation = hourly['precipitation_probability'];
      final DateTime curHour = DateTime(
          currentWeatherTime.year,
          currentWeatherTime.month,
          currentWeatherTime.day,
          currentWeatherTime.hour);
      final int currentIndex = times.indexWhere((t) {
        final dt = DateTime.parse(t);
        return dt.year == curHour.year &&
            dt.month == curHour.month &&
            dt.day == curHour.day &&
            dt.hour == curHour.hour;
      });
      final int startIndex = currentIndex == -1 ? 0 : currentIndex;
      final int itemCount = min(24, times.length - startIndex);

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 200,
            child: Scrollbar(
              thumbVisibility: true,
              controller: controller,
              child: ScrollConfiguration(
                behavior: MyCustomScrollBehavior(),
                child: ListView.separated(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: itemCount,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final int idx = startIndex + index;
                    final DateTime forecastTime = DateTime.parse(times[idx]);
                    final bool isCurrent = index == 0;
                    final int code = codes[idx] as int;
                    final String description =
                        weatherDescriptions[code] ?? 'Unknown';
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            isCurrent
                                ? 'Now'
                                : DateFormat('ha').format(forecastTime),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          buildWeatherIcon(
                              code, forecastTime, 40, false, sunrise, sunset),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          if (precipitation != null &&
                              idx < precipitation.length)
                            Text(
                              '${precipitation[idx].round()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          Text(
                            '${temps[idx].round()}°${useMetric ? "C" : "F"}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget buildDailyForecast(
    Map<String, dynamic> daily, ScrollController controller, bool useMetric) {
  return Builder(
    builder: (context) {
      final List<dynamic> times = daily['time'];
      final List<dynamic> maxTemps = daily['temperature_2m_max'];
      final List<dynamic> minTemps = daily['temperature_2m_min'];
      final List<dynamic> codes = daily['weathercode'];
      final List<dynamic>? percents = daily['precipitation_probability_max'];
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 220,
            child: Scrollbar(
              thumbVisibility: true,
              controller: controller,
              child: ScrollConfiguration(
                behavior: MyCustomScrollBehavior(),
                child: ListView.separated(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: times.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final DateTime date = DateTime.parse(times[index]);
                    final bool isToday = date.day == DateTime.now().day;
                    final int code = codes[index] as int;
                    final String desc = weatherDescriptions[code] ?? 'Unknown';
                    final String precip =
                        (percents != null && index < percents.length)
                            ? '${percents[index].round()}%'
                            : '0%';
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            isToday ? 'Today' : DateFormat('E').format(date),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                              color: Colors.white,
                            ),
                          ),
                          buildWeatherIcon(code, date, 40, true),
                          Text(
                            desc,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          Text(
                            precip,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            '${maxTemps[index].round()}°${useMetric ? "C" : "F"} / ${minTemps[index].round()}°${useMetric ? "C" : "F"}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget buildWeatherIcon(
    int code, DateTime? dateTime, double size, bool forceDay,
    [DateTime? sunrise, DateTime? sunset]) {
  final bool isNight = (!forceDay && dateTime != null)
      ? ((sunrise != null && sunset != null)
          ? (dateTime.hour < sunrise.hour || dateTime.hour > sunset.hour)
          : (dateTime.hour >= 18 || dateTime.hour < 6))
      : false;
  final double iconSize = size;
  switch (code) {
    case 0:
      return BoxedIcon(
          isNight ? WeatherIcons.night_clear : WeatherIcons.day_sunny,
          size: iconSize,
          color: isNight ? const Color(0xFF486581) : const Color(0xFFFF9D00));
    case 1:
    case 2:
      return BoxedIcon(
          isNight
              ? WeatherIcons.night_alt_partly_cloudy
              : WeatherIcons.day_cloudy_high,
          size: iconSize,
          color: isNight ? const Color(0xFF486581) : const Color(0xFF62B2FF));
    case 3:
      return BoxedIcon(WeatherIcons.cloudy,
          size: iconSize,
          color: isNight ? const Color(0xFF486581) : const Color(0xFF62B2FF));
    case 45:
    case 48:
      return BoxedIcon(WeatherIcons.fog,
          size: iconSize,
          color: isNight ? const Color(0xFF7A8B9A) : const Color(0xFF9FB3C8));
    case 51:
      return BoxedIcon(WeatherIcons.sprinkle,
          size: iconSize,
          color: isNight ? const Color(0xFF3178C6) : const Color(0xFF4098D7));
    case 53:
    case 55:
      return BoxedIcon(WeatherIcons.rain_mix,
          size: iconSize,
          color: isNight ? const Color(0xFF3178C6) : const Color(0xFF4098D7));
    case 61:
    case 63:
    case 65:
      return BoxedIcon(WeatherIcons.rain,
          size: iconSize,
          color: isNight ? const Color(0xFF25507A) : const Color(0xFF3178C6));
    case 71:
    case 73:
    case 75:
    case 77:
      return BoxedIcon(WeatherIcons.snow,
          size: iconSize,
          color: isNight ? const Color(0xFF607D8B) : const Color(0xFF90CDF4));
    case 80:
    case 81:
      return BoxedIcon(WeatherIcons.showers,
          size: iconSize,
          color: isNight ? const Color(0xFF1F3E5A) : const Color(0xFF3178C6));
    case 82:
      return BoxedIcon(WeatherIcons.storm_showers,
          size: iconSize,
          color: isNight ? const Color(0xFF1F3E5A) : const Color(0xFF3178C6));
    case 85:
    case 86:
      return BoxedIcon(WeatherIcons.snow,
          size: iconSize,
          color: isNight ? const Color(0xFF607D8B) : const Color(0xFF90CDF4));
    case 95:
    case 96:
    case 99:
      return BoxedIcon(WeatherIcons.thunderstorm,
          size: iconSize,
          color: isNight ? const Color(0xFF553C7B) : const Color(0xFF4098D7));
    default:
      return BoxedIcon(WeatherIcons.na, size: iconSize, color: Colors.grey);
  }
}

Widget buildCurrentTemperature(double temp, bool useMetric) {
  return Text(
    '${temp.round()}°${useMetric ? "C" : "F"}',
    style: const TextStyle(fontSize: 48),
  );
}

Widget buildWindSpeed(double speed, String direction, bool useMetric) {
  return Text(
    '$speed ${useMetric ? "km/h" : "mph"} $direction',
    style: const TextStyle(fontSize: 16),
  );
}

class CurrentWeatherWidget extends StatelessWidget {
  final WeatherData weatherData;
  final DateTime? lastUpdated;
  final bool isCurrentLocationSelected;
  final Location? selectedLocation;
  final bool useMetric;

  const CurrentWeatherWidget({
    super.key,
    required this.weatherData,
    this.lastUpdated,
    required this.isCurrentLocationSelected,
    this.selectedLocation,
    required this.useMetric,
  });

  // Replace the helper to use a warmer color scheme for current weather only
  Widget _buildWeatherIcon(int code, DateTime dateTime, double size,
      [bool forceDay = false, DateTime? sunrise, DateTime? sunset]) {
    return _buildCurrentWeatherIcon(
        code, dateTime, size, forceDay, sunrise, sunset);
  }

  Widget _buildCurrentWeatherIcon(int code, DateTime dateTime, double size,
      bool forceDay, DateTime? sunrise, DateTime? sunset) {
    final bool isNight = (!forceDay)
        ? ((sunrise != null && sunset != null)
            ? (dateTime.hour < sunrise.hour || dateTime.hour > sunset.hour)
            : (dateTime.hour >= 18 || dateTime.hour < 6))
        : false;
    switch (code) {
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
        return BoxedIcon(WeatherIcons.na, size: size, color: Colors.grey);
    }
  }

  // Updated _buildWeatherDetail: fixed width added for uniform sizing
  Widget _buildWeatherDetail(IconData icon, String label, String value,
      [Color? bgColor, Color? textColor]) {
    return Container(
      width: 120, // fixed width for consistent box size
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            // Darker blue gradient for better contrast
            const Color(0xFF1A237E), // Dark blue
            const Color(0xFF303F9F), // Slightly lighter blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white, // Brighter text
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor?.withOpacity(0.95) ??
                  Colors
                      .white, // Slightly adjusted opacity for better visibility
            ),
          ),
        ],
      ),
    );
  }

  String _getUVDescription(double uvIndex) {
    if (uvIndex < 3) {
      return 'Low';
    } else if (uvIndex < 6) {
      return 'Moderate';
    } else if (uvIndex < 8) {
      return 'High';
    } else if (uvIndex < 11) {
      return 'Very High';
    } else {
      return 'Extreme';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String rainChance = '0%';
    String feelsLikeTemp = 'N/A';
    String airQualityDescription = 'Air quality data unavailable';
    Color airQualityColor = Colors.grey;
    String pm25Value = 'N/A';

    if (weatherData.airQualityData != null) {
      final (description, color, _, _, _) =
          AirQualityUtils.getAQIInfo(weatherData.airQualityData!);
      airQualityDescription = description;
      airQualityColor = color;
    }

    if (weatherData.hourly['time'] != null) {
      final List<String> timeList =
          List<String>.from(weatherData.hourly['time']);
      final List<dynamic> precipitation =
          weatherData.hourly['precipitation_probability'];
      final List<dynamic> apparentTemps =
          weatherData.hourly['apparent_temperature'];
      final DateTime locationNow = weatherData.currentWeatherTime;
      final DateTime currentHour = DateTime(locationNow.year, locationNow.month,
          locationNow.day, locationNow.hour);
      final int currentIndex = timeList.indexWhere((timeStr) {
        final DateTime forecastTime = DateTime.parse(timeStr);
        return forecastTime.year == currentHour.year &&
            forecastTime.month == currentHour.month &&
            forecastTime.day == currentHour.day &&
            forecastTime.hour == currentHour.hour;
      });
      if (currentIndex != -1 &&
          precipitation.isNotEmpty &&
          currentIndex < precipitation.length) {
        rainChance = '${precipitation[currentIndex].round()}%';
      }
      if (currentIndex != -1 &&
          apparentTemps.isNotEmpty &&
          currentIndex < apparentTemps.length) {
        feelsLikeTemp = '${apparentTemps[currentIndex].round()}°';
      }
    }

    return Card(
      elevation: isDark ? 4 : 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.grey.shade900,
                    Colors.grey.shade800,
                  ]
                : [
                    const Color.fromARGB(255, 167, 215, 255),
                    const Color.fromARGB(255, 194, 216, 247)
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 24 : 32, vertical: isSmall ? 30 : 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (lastUpdated != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(1, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time,
                            size: 16,
                            color: isDark ? Colors.blue.shade300 : Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'Updated: ${DateFormat('h:mm a').format(lastUpdated!)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    isDark ? Colors.blue.shade300 : Colors.blue,
                              ),
                        ),
                      ],
                    ),
                  ),
                const Icon(Icons.wb_sunny, color: Colors.amber, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            // Location display
            Text(
              isCurrentLocationSelected
                  ? 'Current Location'
                  : selectedLocation?.displayName ?? '',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontSize: 24, color: Colors.blueAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Main weather display with animated icon and stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Removed AnimatedSwitcher for smooth icon update
                _buildWeatherIcon(
                  weatherData.currentWeatherCode,
                  weatherData.currentWeatherTime,
                  70,
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weatherData.currentTemp.toStringAsFixed(1)}°${useMetric ? "C" : "F"}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent),
                    ),
                    Text(
                      weatherDescriptions[weatherData.currentWeatherCode] ??
                          'Unknown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 20,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Weather details
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildWeatherDetail(
                    Icons.thermostat, 'Feels like', feelsLikeTemp, null, null),
                _buildWeatherDetail(Icons.wb_sunny, 'UV Index',
                    _getUVDescription(weatherData.uvIndex), null, null),
                _buildWeatherDetail(
                    Icons.navigation,
                    'Wind',
                    '${weatherData.currentWindSpeed} ${useMetric ? "km/h" : "mph"} ${weatherData.getWindDirection()}',
                    null,
                    null),
                _buildWeatherDetail(
                    Icons.water_drop, 'Rain', rainChance, null, null),
                _buildWeatherDetail(
                    Icons.wb_twilight,
                    'Sunrise',
                    DateFormat('h:mm a').format(weatherData.sunrise),
                    null,
                    null),
                _buildWeatherDetail(
                    Icons.nights_stay,
                    'Sunset',
                    DateFormat('h:mm a').format(weatherData.sunset),
                    null,
                    null),
                _buildWeatherDetail(
                  WeatherIcons.dust,
                  'Air Quality',
                  airQualityDescription,
                  Color(0xFF80DFFF),
                  airQualityColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
