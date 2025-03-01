import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' show min;
import 'package:weather_icons/weather_icons.dart';
import '../services/weather_service.dart';
import '../utils/custom_scroll_behavior.dart';
import '../utils/weather_code_mapper.dart'; // Add this import
import 'air_quality_widget.dart';
import 'dart:ui' as ui;
import '../utils/weather_utils.dart';
import '../utils/ui_constants.dart';
import 'weather_description_box.dart';
import 'precipitation_indicator.dart';

// Add these utility classes at the top level
extension WeatherPerformanceUtils on Widget {
  Widget withRepaintBoundary() {
    return RepaintBoundary(child: this);
  }
}

mixin ChartOptimizationMixin<T extends StatefulWidget> on State<T> {
  Paint? _linePaint;
  Paint? _fillPaint;

  Paint getLinePaint(Color color) {
    return _linePaint ??= Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
  }

  Paint getFillPaint(List<Color> colors, {bool vertical = true}) {
    return _fillPaint ??= Paint()
      ..shader = ui.Gradient.linear(
        vertical ? const Offset(0, 0) : const Offset(0, 10),
        vertical ? const Offset(0, 100) : const Offset(100, 10),
        colors,
        [0.0, 1.0],
      )
      ..style = PaintingStyle.fill;
  }

  void _precalculateValues() {
    // For subclasses to override
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precalculateValues();
  }
}

// Simple data class to efficiently store hourly weather data
class HourlyWeatherPoint {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final double precipProbability;

  const HourlyWeatherPoint({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.precipProbability,
  });
}

// Add this constant for consistent spacing
const sizedBoxHeight16 = SizedBox(height: 16);

// buildHourlyForecast function removed

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
                    final String desc = getWeatherDescription(code);
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
  return WeatherUtils.buildIcon(
      code, dateTime, size, forceDay, sunrise, sunset);
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
    // Sanitize the code first
    int safeCode = WeatherUtils.sanitizeWeatherCode(code);

    // Continue with the existing switch statement using safeCode
    final bool isNight = (!forceDay)
        ? ((sunrise != null && sunset != null)
            ? (dateTime.hour < sunrise.hour || dateTime.hour > sunset.hour)
            : (dateTime.hour >= 18 || dateTime.hour < 6))
        : false;
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
                      WeatherUtils.getDescription(
                          weatherData.currentWeatherCode),
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

class WeatherChart extends StatefulWidget {
  final Map<String, dynamic> hourly;
  final DateTime currentTime;
  final bool useMetric;

  const WeatherChart({
    super.key,
    required this.hourly,
    required this.currentTime,
    required this.useMetric,
  });

  @override
  State<WeatherChart> createState() => _WeatherChartState();
}

class _WeatherChartState extends State<WeatherChart>
    with ChartOptimizationMixin {
  int? _highlightedHour;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Change to scroll to the very left initially, instead of offsetting by 40
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Changed from 40.0 to 0.0
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safely access data
    final List<String> times = List<String>.from(widget.hourly['time'] ?? []);
    if (times.isEmpty) return const SizedBox.shrink(); // No data

    final List<num> temps =
        List<num>.from(widget.hourly['temperature_2m'] ?? []);
    final List<num> precipProbs =
        List<num>.from(widget.hourly['precipitation_probability'] ?? []);
    final List<num> precipAmounts =
        List<num>.from(widget.hourly['precipitation'] ?? []);

    if (temps.isEmpty) return const SizedBox.shrink(); // No temperature data

    // Find the current hour index
    final DateTime curHour = DateTime(
      widget.currentTime.year,
      widget.currentTime.month,
      widget.currentTime.day,
      widget.currentTime.hour,
    );

    int currentIndex = times.indexWhere((t) {
      try {
        final dt = DateTime.parse(t);
        return dt.year == curHour.year &&
            dt.month == curHour.month &&
            dt.day == curHour.day &&
            dt.hour == curHour.hour;
      } catch (e) {
        return false;
      }
    });

    if (currentIndex == -1) currentIndex = 0;

    final int startIdx = currentIndex;
    final int endIdx =
        startIdx + 24 <= times.length ? startIdx + 24 : times.length;

    if (startIdx >= endIdx) return const SizedBox.shrink(); // Invalid range

    // Prepare data for the chart
    final displayTimes = times.sublist(startIdx, endIdx);
    final displayTemps =
        temps.sublist(startIdx, endIdx).map((t) => t.toDouble()).toList();

    final displayPrecipProbs =
        precipProbs.isNotEmpty && startIdx < precipProbs.length
            ? precipProbs
                .sublist(startIdx,
                    endIdx > precipProbs.length ? precipProbs.length : endIdx)
                .map((p) => p.toDouble())
                .toList()
            : List<double>.filled(displayTimes.length, 0.0);

    final displayPrecipAmounts = precipAmounts.isNotEmpty &&
            startIdx < precipAmounts.length
        ? precipAmounts
            .sublist(startIdx,
                endIdx > precipAmounts.length ? precipAmounts.length : endIdx)
            .map((p) => p.toDouble())
            .toList()
        : List<double>.filled(displayTimes.length, 0.0);

    // Calculate min and max temperature for scaling
    if (displayTemps.isEmpty) return const SizedBox.shrink();

    double minTemp = displayTemps.reduce((a, b) => a < b ? a : b);
    double maxTemp = displayTemps.reduce((a, b) => a > b ? a : b);

    // Add padding to min/max range
    final tempRange = maxTemp - minTemp;
    minTemp = minTemp - (tempRange * 0.1);
    maxTemp = maxTemp + (tempRange * 0.1);

    // Calculate chart height based on temperature range
    final double chartHeight =
        tempRange < 10 ? 150.0 : (tempRange < 20 ? 180.0 : 220.0);

    // Increase hourWidth for better spacing between items
    const double hourWidth = 80.0; // Increased from 68.0 for more spacing

    // Get sunrise and sunset times from the daily data if available
    DateTime? sunrise, sunset;
    if (widget.hourly['sunrise_time'] != null &&
        widget.hourly['sunset_time'] != null) {
      final sunriseList = widget.hourly['sunrise_time'];
      final sunsetList = widget.hourly['sunset_time'];
      if (sunriseList.isNotEmpty && sunsetList.isNotEmpty) {
        sunrise = DateTime.parse(sunriseList[0]);
        sunset = DateTime.parse(sunsetList[0]);
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hourly Forecast',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: chartHeight +
                  120, // Increased height to accommodate weather descriptions
              child: ScrollConfiguration(
                behavior: MyCustomScrollBehavior(),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(8),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: displayTimes.length * hourWidth,
                        height: chartHeight + 120, // Match the increased height
                        child: Stack(
                          children: [
                            // Weather icons - with improved centering
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 40,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children:
                                    List.generate(displayTimes.length, (i) {
                                  // Get the weather code for this hour
                                  final weatherCodes =
                                      widget.hourly['weathercode'];
                                  int weatherCode = 0; // Default clear sky
                                  if (weatherCodes != null &&
                                      i + startIdx < weatherCodes.length) {
                                    weatherCode =
                                        WeatherUtils.sanitizeWeatherCode(
                                            weatherCodes[i + startIdx]);
                                  }

                                  // Parse the date time for this forecast hour
                                  final forecastTime =
                                      DateTime.parse(displayTimes[i]);

                                  return Container(
                                    width: hourWidth,
                                    alignment: Alignment.center,
                                    child: buildWeatherIcon(
                                        weatherCode,
                                        forecastTime,
                                        24,
                                        false,
                                        sunrise,
                                        sunset),
                                  );
                                }),
                              ),
                            ),

                            // Weather descriptions - improved layout
                            Positioned(
                              top: 40,
                              left: 0,
                              right: 0,
                              height: 20,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children:
                                    List.generate(displayTimes.length, (i) {
                                  final weatherCodes =
                                      widget.hourly['weathercode'];
                                  int weatherCode = 0;
                                  if (weatherCodes != null &&
                                      i + startIdx < weatherCodes.length) {
                                    weatherCode =
                                        WeatherUtils.sanitizeWeatherCode(
                                            weatherCodes[i + startIdx]);
                                  }

                                  final description =
                                      getWeatherDescription(weatherCode);

                                  return Container(
                                    width: hourWidth,
                                    alignment: Alignment.center,
                                    child: WeatherDescriptionBox(
                                      description: description,
                                      isHighlighted: i == _highlightedHour,
                                    ),
                                  );
                                }),
                              ),
                            ),

                            // Temperature chart - keep adjusted top position
                            Positioned(
                              top:
                                  60, // Increase from 50 to 60 to make room for descriptions
                              left: 0,
                              right: 0,
                              height: chartHeight,
                              child: CustomPaint(
                                size: Size(displayTimes.length * hourWidth,
                                    chartHeight),
                                painter: TemperatureChartPainter(
                                  temperatures: displayTemps,
                                  minTemp: minTemp,
                                  maxTemp: maxTemp,
                                  hourWidth: hourWidth,
                                  highlightedHour: _highlightedHour,
                                  temperatureUnit:
                                      widget.useMetric ? '°C' : '°F',
                                  precipitationProbabilities:
                                      displayPrecipProbs,
                                  useEnhancedGradient: true,
                                ),
                              ),
                            ),

                            // Precipitation indicators - improved layout
                            Positioned(
                              bottom: 40,
                              left: 0,
                              right: 0,
                              height:
                                  20, // Reduced from 28 to 20 to make them less tall
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children:
                                    List.generate(displayTimes.length, (i) {
                                  final probability =
                                      i < displayPrecipProbs.length
                                          ? displayPrecipProbs[i]
                                          : 0.0;

                                  return Container(
                                    width: hourWidth,
                                    alignment: Alignment.center,
                                    child: PrecipitationIndicator(
                                      probability: probability,
                                      width: hourWidth *
                                          0.7, // Slightly narrower for better appearance
                                      isHighlighted: i == _highlightedHour,
                                    ),
                                  );
                                }),
                              ),
                            ),

                            // Hour labels - improved layout
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 30,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children:
                                    List.generate(displayTimes.length, (i) {
                                  try {
                                    final dateTime =
                                        DateTime.parse(displayTimes[i]);
                                    final isCurrentHour = i == 0;
                                    final formattedHour = isCurrentHour
                                        ? 'Now'
                                        : DateFormat('ha')
                                            .format(dateTime)
                                            .toLowerCase();

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _highlightedHour =
                                              i == _highlightedHour ? null : i;
                                        });
                                      },
                                      child: Container(
                                        width: hourWidth,
                                        height: 30,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: i == _highlightedHour
                                              ? Colors.blue.withOpacity(0.15)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          formattedHour,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isCurrentHour ||
                                                    i == _highlightedHour
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isCurrentHour
                                                ? Colors.blue
                                                : i == _highlightedHour
                                                    ? Colors.blue.shade300
                                                    : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    return SizedBox(width: hourWidth);
                                  }
                                }),
                              ),
                            ),

                            // Enhanced tooltip with more details
                            if (_highlightedHour != null &&
                                _highlightedHour! < displayTimes.length &&
                                _highlightedHour! < displayTemps.length)
                              Positioned(
                                top: 5,
                                left: (_highlightedHour! * hourWidth) - 70,
                                child: Material(
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.transparent,
                                  child: Container(
                                    width: 140,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black87,
                                          Colors.blueGrey.shade800,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            buildWeatherIcon(
                                                widget.hourly['weathercode'][
                                                    startIdx +
                                                        _highlightedHour!],
                                                DateTime.parse(displayTimes[
                                                    _highlightedHour!]),
                                                20,
                                                false, // Don't force day
                                                sunrise,
                                                sunset),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                DateFormat('EEE, h:mm a').format(
                                                    DateTime.parse(displayTimes[
                                                        _highlightedHour!])),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${displayTemps[_highlightedHour!].toStringAsFixed(1)}${widget.useMetric ? '°C' : '°F'}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.opacity,
                                                size: 14, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text(
                                              _highlightedHour! <
                                                      displayPrecipProbs.length
                                                  ? '${displayPrecipProbs[_highlightedHour!].round()}% chance of rain'
                                                  : 'No rain',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_highlightedHour! <
                                            widget
                                                .hourly['relative_humidity_2m']
                                                .length)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.water_drop,
                                                    size: 14,
                                                    color:
                                                        Colors.lightBlueAccent),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Humidity: ${widget.hourly['relative_humidity_2m'][startIdx + _highlightedHour!]}%',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TemperatureChartPainter extends CustomPainter {
  final List<double> temperatures;
  final List<double> precipitationProbabilities;
  final double minTemp;
  final double maxTemp;
  final double hourWidth;
  final int? highlightedHour;
  final String temperatureUnit;
  final bool useEnhancedGradient; // New parameter for enhanced gradient

  TemperatureChartPainter({
    required this.temperatures,
    required this.minTemp,
    required this.maxTemp,
    required this.hourWidth,
    required this.precipitationProbabilities,
    required this.temperatureUnit,
    this.highlightedHour,
    this.useEnhancedGradient =
        false, // Default to false for backward compatibility
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawTemperatureLine(canvas, size);
    _drawTemperaturePoints(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1.0;

    // Horizontal grid lines - 4 evenly spaced lines
    for (int i = 1; i < 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Temperature range labels on left side
    final textStyle = ui.TextStyle(
      color: Colors.grey[400],
      fontSize: 10,
    );

    final tempRange = maxTemp - minTemp;
    final tempStep = tempRange / 4;

    for (int i = 0; i <= 4; i++) {
      final temp = maxTemp - (i * tempStep);
      final y = (size.height / 4) * i;

      final paragraphBuilder =
          ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.right))
            ..pushStyle(textStyle)
            ..addText('${temp.round()}°');

      final paragraph = paragraphBuilder.build()
        ..layout(const ui.ParagraphConstraints(width: 30));

      canvas.drawParagraph(paragraph, Offset(-35, y - paragraph.height / 2));
    }
  }

  void _drawTemperatureLine(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // Create a gradient that transitions from orange to transparent (background)
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height), // Start at bottom
        Offset(0, 0), // End at top
        [
          Colors.transparent, // Bottom color: transparent (background)
          Colors.orangeAccent.withOpacity(0.2), // Middle-bottom: slight orange
          Colors.orangeAccent.withOpacity(0.4), // Middle-top: more orange
          Colors.orangeAccent.withOpacity(0.6), // Top: most vibrant orange
        ],
        [0.0, 0.4, 0.7, 1.0], // Adjusted color stops for smoother transition
      )
      ..style = PaintingStyle.fill;

    // Rest of the method stays the same (path creation, etc.)
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < temperatures.length; i++) {
      final x = i * hourWidth + (hourWidth / 2);
      final normalizedTemp =
          1 - ((temperatures[i] - minTemp) / (maxTemp - minTemp));
      final y = normalizedTemp * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == temperatures.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  void _drawTemperaturePoints(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.fill;

    final textStyle = ui.TextStyle(
      color: Colors.white.withOpacity(0.8),
      fontSize: 11,
      fontWeight: ui.FontWeight.bold,
    );

    final highlightTextStyle = ui.TextStyle(
      color: Colors.orangeAccent,
      fontSize: 12,
      fontWeight: ui.FontWeight.bold,
    );

    for (int i = 0; i < temperatures.length; i++) {
      final x = i * hourWidth + (hourWidth / 2);
      final normalizedTemp =
          1 - ((temperatures[i] - minTemp) / (maxTemp - minTemp));
      final y = normalizedTemp * size.height;

      final isHighlighted = i == highlightedHour;

      // Draw dot
      canvas.drawCircle(Offset(x, y), isHighlighted ? 5.0 : 3.0,
          isHighlighted ? highlightPaint : dotPaint);

      // Draw temperature value for all hours
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
      ))
        ..pushStyle(isHighlighted ? highlightTextStyle : textStyle)
        ..addText('${temperatures[i].round()}°');

      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: hourWidth));

      // Position temp value above or below dot depending on position in chart
      final textY = normalizedTemp < 0.2
          ? y + 15 // If near top, draw below
          : y - paragraph.height - 5; // Otherwise draw above

      canvas.drawParagraph(paragraph, Offset(x - (paragraph.width / 2), textY));
    }
  }

  @override
  bool shouldRepaint(covariant TemperatureChartPainter oldDelegate) =>
      minTemp != oldDelegate.minTemp ||
      maxTemp != oldDelegate.maxTemp ||
      highlightedHour != oldDelegate.highlightedHour ||
      useEnhancedGradient != oldDelegate.useEnhancedGradient;
}

class PrecipitationIndicatorPainter extends CustomPainter {
  final List<double> probabilities;
  final List<double> amounts;
  final double hourWidth;
  final int? highlightedHour;
  final bool showText;

  PrecipitationIndicatorPainter({
    required this.probabilities,
    required this.amounts,
    required this.hourWidth,
    this.highlightedHour,
    this.showText = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < probabilities.length; i++) {
      final probability = probabilities[i];
      final amount = amounts[i];

      // Only continue if there's any probability at all
      if (probability <= 0) continue;

      // Define a color gradient from light blue to dark blue with MORE gradual steps
      final List<Color> blueGradient = [
        const Color(0xFFBBDEFB), // Very light blue (for 1%)
        const Color(0xFF90CAF9), // Light blue (for 10%)
        const Color(0xFF64B5F6), // Light-medium blue (for 25%)
        const Color(0xFF42A5F5), // Medium blue (for 40%)
        const Color(0xFF2196F3), // Medium-strong blue (for 55%)
        const Color(0xFF1E88E5), // Strong blue (for 70%)
        const Color(0xFF1976D2), // Strong-dark blue (for 85%)
        const Color(0xFF1565C0), // Dark blue (for 95%)
        const Color(0xFF0D47A1), // Very dark blue (for 100%)
      ];

      // Normalize probability to get exact position in our color gradient (0-8 range)
      final normalizedPosition =
          (probability / 100) * (blueGradient.length - 1);

      // Get the two colors to interpolate between
      final lowerIndex = normalizedPosition.floor();
      final upperIndex = normalizedPosition.ceil();

      // Calculate the exact fraction between the two colors (0.0-1.0)
      final fraction = normalizedPosition - lowerIndex;

      // Get the final color by interpolating between the two nearest colors
      final Color color;
      if (lowerIndex == upperIndex) {
        // Handle edge case where floor and ceiling are the same
        color = blueGradient[lowerIndex];
      } else {
        // Normal case: interpolate between two colors
        color = Color.lerp(
          blueGradient[lowerIndex],
          blueGradient[upperIndex],
          fraction,
        )!; // The ! is just to assert the result won't be null
      }

      // Make the precipitation box with rounded corners
      final rect = Rect.fromLTWH((i * hourWidth) + (hourWidth * 0.15), 0,
          hourWidth * 0.7, size.height);

      final isHighlighted = i == highlightedHour;

      // Apply opacity with minimum threshold for visibility
      // Higher probability = slightly more opaque
      final minOpacity = 0.7; // Increased from 0.4 for better visibility
      final maxOpacity = 0.95; // Increased from 0.9 for consistency
      final fillOpacity =
          minOpacity + (probability / 100) * (maxOpacity - minOpacity);

      // Fill paint with color determined purely by probability
      final fillPaint = Paint()
        ..color = color.withOpacity(fillOpacity)
        ..style = PaintingStyle.fill;

      // Border paint matching the fill color (but full opacity)
      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighlighted ? 1.5 : 1.0;

      // Use consistent rounded corners
      final roundedRect =
          RRect.fromRectAndRadius(rect, const Radius.circular(8));

      // Draw fill and border
      canvas.drawRRect(roundedRect, fillPaint);
      canvas.drawRRect(roundedRect, borderPaint);

      // Text showing precipitation percentage
      if (showText) {
        // Text style - use white text with shadow for all boxes
        final textStyle = ui.TextStyle(
          color: Colors.white,
          fontSize: isHighlighted ? 11 : 10,
          fontWeight: probability > 50 || isHighlighted
              ? ui.FontWeight.bold
              : ui.FontWeight.normal,
          shadows: [
            ui.Shadow(
              blurRadius: 2,
              color: Colors.black.withOpacity(0.7),
              offset: const Offset(0, 1),
            ),
          ],
        );

        final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: ui.TextAlign.center,
        ))
          ..pushStyle(textStyle)
          ..addText('${probability.round()}%');

        final paragraph = paragraphBuilder.build()
          ..layout(ui.ParagraphConstraints(width: hourWidth * 0.7));

        // Center the text in the box
        final textX = (i * hourWidth) +
            (hourWidth * 0.15) +
            ((hourWidth * 0.7 - paragraph.width) / 2);
        final textY = (size.height - paragraph.height) / 2;

        canvas.drawParagraph(paragraph, Offset(textX, textY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant PrecipitationIndicatorPainter oldDelegate) =>
      highlightedHour != oldDelegate.highlightedHour ||
      showText != oldDelegate.showText;
}

Widget buildWeeklyForecastGradient(
    Map<String, dynamic> daily, ScrollController controller, bool useMetric) {
  return Builder(
    builder: (context) {
      final List<dynamic> times = daily['time'];
      final List<dynamic> maxTemps = daily['temperature_2m_max'];
      final List<dynamic> minTemps = daily['temperature_2m_min'];
      final List<dynamic> codes = daily['weathercode'];
      final List<dynamic>? percents = daily['precipitation_probability_max'];
      final List<dynamic>? windSpeeds = daily['wind_speed_10m_max'];

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Weekly Forecast',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(),
            SizedBox(
              height: 300, // More room for precipitation visualization
              child: ListView.builder(
                controller: controller,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: times.length,
                itemBuilder: (context, index) {
                  final DateTime date = DateTime.parse(times[index]);
                  final bool isToday = date.day == DateTime.now().day &&
                      date.month == DateTime.now().month;
                  final int code = codes[index] as int;
                  final String desc = getWeatherDescription(code);

                  // Calculate precipitation probability
                  final double precipProb =
                      percents != null && index < percents.length
                          ? (percents[index] as num).toDouble()
                          : 0.0;

                  // Get wind speed if available
                  final String windSpeed = windSpeeds != null &&
                          index < windSpeeds.length
                      ? '${windSpeeds[index].round()} ${useMetric ? "km/h" : "mph"}'
                      : 'N/A';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.grey.shade800.withOpacity(0.6),
                      ),
                      child: Row(
                        children: [
                          // Date column
                          Container(
                            width: 70,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Colors.blue.withOpacity(0.3)
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(14)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isToday
                                      ? 'Today'
                                      : DateFormat('EEE').format(date),
                                  style: TextStyle(
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d').format(date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Weather icon
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: buildWeatherIcon(code, date, 36, true),
                          ),

                          // Weather info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  desc,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Wind: $windSpeed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Temperature
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Text(
                                  '${maxTemps[index].round()}°',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '/${minTemps[index].round()}°',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Use CustomPaint to draw precipitation bars at the bottom of each day
            Container(
              height: 50,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width - 64, 50),
                painter: WeeklyPrecipitationPainter(
                  probabilities: percents != null
                      ? List<double>.from(
                          percents.map((p) => (p as num).toDouble()))
                      : List<double>.filled(times.length, 0.0),
                  days: times.length,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class WeeklyPrecipitationPainter extends CustomPainter {
  final List<double> probabilities;
  final int days;

  WeeklyPrecipitationPainter({
    required this.probabilities,
    required this.days,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double barWidth = size.width / days;
    const double barPadding = 8.0;

    // Draw labels
    final textStyle = ui.TextStyle(
      color: Colors.white70,
      fontSize: 10,
    );

    final paragraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.center))
          ..pushStyle(textStyle)
          ..addText('Precipitation Probability');

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: size.width));

    canvas.drawParagraph(paragraph, Offset(0, 0));

    // Define color gradient from light blue to dark blue
    final List<Color> blueGradient = [
      const Color(0xFFBBDEFB), // Very light blue (for 1%)
      const Color(0xFF90CAF9), // Light blue (for 10%)
      const Color(0xFF64B5F6), // Light-medium blue (for 25%)
      const Color(0xFF42A5F5), // Medium blue (for 40%)
      const Color(0xFF2196F3), // Medium-strong blue (for 55%)
      const Color(0xFF1E88E5), // Strong blue (for 70%)
      const Color(0xFF1976D2), // Strong-dark blue (for 85%)
      const Color(0xFF1565C0), // Dark blue (for 95%)
      const Color(0xFF0D47A1), // Very dark blue (for 100%)
    ];

    // Draw each precipitation probability bar
    for (int i = 0; i < days && i < probabilities.length; i++) {
      final double probability = probabilities[i];

      if (probability <= 0) continue;

      // Calculate gradient color based on probability
      final normalizedPosition =
          (probability / 100) * (blueGradient.length - 1);
      final lowerIndex = normalizedPosition.floor();
      final upperIndex = normalizedPosition.ceil();
      final fraction = normalizedPosition - lowerIndex;

      // Get interpolated color
      final Color color;
      if (lowerIndex == upperIndex) {
        color = blueGradient[lowerIndex];
      } else {
        color = Color.lerp(
          blueGradient[lowerIndex],
          blueGradient[upperIndex],
          fraction,
        )!;
      }

      // Calculate bar height based on probability
      final maxHeight = size.height - 20; // Subtract text height
      final barHeight = (probability / 100) * maxHeight;

      // Calculate bar position
      final rect = Rect.fromLTWH(i * barWidth + barPadding / 2,
          size.height - barHeight, barWidth - barPadding, barHeight);

      // Draw the bar with rounded top corners
      final roundRect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      // Fill paint using our gradient color
      final fillPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      // Border paint for outline
      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawRRect(roundRect, fillPaint);
      canvas.drawRRect(roundRect, borderPaint);

      // Add text showing percentage
      if (probability >= 10) {
        final textStyle = ui.TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: ui.FontWeight.bold,
        );

        final paragraphBuilder = ui.ParagraphBuilder(
            ui.ParagraphStyle(textAlign: ui.TextAlign.center))
          ..pushStyle(textStyle)
          ..addText('${probability.round()}%');

        final paragraph = paragraphBuilder.build()
          ..layout(ui.ParagraphConstraints(width: barWidth - barPadding));

        // Position text inside the bar if tall enough, otherwise above it
        final textY = barHeight > 20
            ? size.height - barHeight + 2
            : size.height - barHeight - paragraph.height - 2;

        canvas.drawParagraph(
            paragraph, Offset(i * barWidth + barPadding / 2, textY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyPrecipitationPainter oldDelegate) =>
      oldDelegate.probabilities != probabilities || oldDelegate.days != days;
}

class WeeklyWeatherChart extends StatefulWidget {
  final Map<String, dynamic> daily;
  final bool useMetric;

  const WeeklyWeatherChart({
    super.key,
    required this.daily,
    required this.useMetric,
  });

  @override
  State<WeeklyWeatherChart> createState() => _WeeklyWeatherChartState();
}

class WeeklyTemperatureChartPainter extends CustomPainter {
  final List<double> maxTemps;
  final List<double> minTemps;
  final double minTemp;
  final double maxTemp;
  final double dayWidth;
  final int? highlightedDay;
  final String temperatureUnit;

  WeeklyTemperatureChartPainter({
    required this.maxTemps,
    required this.minTemps,
    required this.minTemp,
    required this.maxTemp,
    required this.dayWidth,
    required this.temperatureUnit,
    this.highlightedDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawTemperatureLines(canvas, size);
    _drawTemperaturePoints(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1.0;

    // Horizontal grid lines - 4 evenly spaced lines
    for (int i = 1; i < 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Temperature range labels on left side
    final textStyle = ui.TextStyle(
      color: Colors.grey[400],
      fontSize: 10,
    );

    final tempRange = maxTemp - minTemp;
    final tempStep = tempRange / 4;

    for (int i = 0; i <= 4; i++) {
      final temp = maxTemp - (i * tempStep);
      final y = (size.height / 4) * i;

      final paragraphBuilder =
          ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.right))
            ..pushStyle(textStyle)
            ..addText('${temp.round()}°');

      final paragraph = paragraphBuilder.build()
        ..layout(const ui.ParagraphConstraints(width: 30));

      canvas.drawParagraph(paragraph, Offset(-35, y - paragraph.height / 2));
    }
  }

  void _drawTemperatureLines(Canvas canvas, Size size) {
    // High temperature line
    final highLinePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // Low temperature line
    final lowLinePaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // Area between high and low temperatures
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          Colors.orange.withOpacity(0.2),
          Colors.cyan.withOpacity(0.2),
        ],
      )
      ..style = PaintingStyle.fill;

    final highPath = Path();
    final lowPath = Path();
    final fillPath = Path();

    for (int i = 0; i < maxTemps.length; i++) {
      final x = i * dayWidth + (dayWidth / 2);
      final highY =
          (1 - ((maxTemps[i] - minTemp) / (maxTemp - minTemp))) * size.height;
      final lowY =
          (1 - ((minTemps[i] - minTemp) / (maxTemp - minTemp))) * size.height;

      if (i == 0) {
        highPath.moveTo(x, highY);
        lowPath.moveTo(x, lowY);
        fillPath.moveTo(x, highY);
      } else {
        highPath.lineTo(x, highY);
        lowPath.lineTo(x, lowY);
        fillPath.lineTo(x, highY);
      }
    }

    // Complete the fill path
    for (int i = maxTemps.length - 1; i >= 0; i--) {
      final x = i * dayWidth + (dayWidth / 2);
      final lowY =
          (1 - ((minTemps[i] - minTemp) / (maxTemp - minTemp))) * size.height;
      fillPath.lineTo(x, lowY);
    }

    // Close the fill path
    if (maxTemps.isNotEmpty) {
      final startX = 0 * dayWidth + (dayWidth / 2);
      final startHighY =
          (1 - ((maxTemps[0] - minTemp) / (maxTemp - minTemp))) * size.height;
      fillPath.lineTo(startX, startHighY);
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(highPath, highLinePaint);
    canvas.drawPath(lowPath, lowLinePaint);
  }

  void _drawTemperaturePoints(Canvas canvas, Size size) {
    final highDotPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    final lowDotPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final highTextStyle = ui.TextStyle(
      color: Colors.orange,
      fontSize: 12,
      fontWeight: ui.FontWeight.bold,
    );

    final lowTextStyle = ui.TextStyle(
      color: Colors.cyan,
      fontSize: 12,
      fontWeight: ui.FontWeight.bold,
    );

    for (int i = 0; i < maxTemps.length; i++) {
      final x = i * dayWidth + (dayWidth / 2);
      final highY =
          (1 - ((maxTemps[i] - minTemp) / (maxTemp - minTemp))) * size.height;
      final lowY =
          (1 - ((minTemps[i] - minTemp) / (maxTemp - minTemp))) * size.height;

      final isHighlighted = i == highlightedDay;

      // Draw high temperature dot
      canvas.drawCircle(
          Offset(x, highY), isHighlighted ? 5.0 : 4.0, highDotPaint);

      // Draw low temperature dot
      canvas.drawCircle(
          Offset(x, lowY), isHighlighted ? 5.0 : 4.0, lowDotPaint);

      // Add white outline for highlighted day
      if (isHighlighted) {
        canvas.drawCircle(Offset(x, highY), 5.0, highlightPaint);
        canvas.drawCircle(Offset(x, lowY), 5.0, highlightPaint);
      }

      // Draw high temperature value
      final highParagraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
      ))
        ..pushStyle(highTextStyle)
        ..addText('${maxTemps[i].round()}°');

      final highParagraph = highParagraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: dayWidth));

      // Draw low temperature value
      final lowParagraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
      ))
        ..pushStyle(lowTextStyle)
        ..addText('${minTemps[i].round()}°');

      final lowParagraph = lowParagraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: dayWidth));

      // Position temperature text
      final highTextY = highY - highParagraph.height - 5;
      final lowTextY = lowY + 5;

      canvas.drawParagraph(
          highParagraph, Offset(x - (highParagraph.width / 2), highTextY));

      canvas.drawParagraph(
          lowParagraph, Offset(x - (lowParagraph.width / 2), lowTextY));
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyTemperatureChartPainter oldDelegate) =>
      minTemp != oldDelegate.minTemp ||
      maxTemp != oldDelegate.maxTemp ||
      highlightedDay != oldDelegate.highlightedDay;
}

class DailyTemperatureChartPainter extends CustomPainter {
  final List<double> maxTemps;
  final List<double> minTemps;
  final double minTemp;
  final double maxTemp;
  final double dayWidth;
  final int? highlightedDay;
  final String temperatureUnit;

  DailyTemperatureChartPainter({
    required this.maxTemps,
    required this.minTemps,
    required this.minTemp,
    required this.maxTemp,
    required this.dayWidth,
    required this.temperatureUnit,
    this.highlightedDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawTemperatureLines(canvas, size);
    _drawTemperaturePoints(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1.0;

    // Horizontal grid lines - 4 evenly spaced lines
    for (int i = 1; i < 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Temperature range labels on left side
    final textStyle = ui.TextStyle(
      color: Colors.grey[400],
      fontSize: 10,
    );

    final tempRange = maxTemp - minTemp;
    final tempStep = tempRange / 4;

    for (int i = 0; i <= 4; i++) {
      final temp = maxTemp - (i * tempStep);
      final y = (size.height / 4) * i;

      final paragraphBuilder =
          ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.right))
            ..pushStyle(textStyle)
            ..addText('${temp.round()}°');

      final paragraph = paragraphBuilder.build()
        ..layout(const ui.ParagraphConstraints(width: 30));

      canvas.drawParagraph(paragraph, Offset(-35, y - paragraph.height / 2));
    }
  }

  void _drawTemperatureLines(Canvas canvas, Size size) {
    // High temperature line
    final highLinePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // Low temperature line
    final lowLinePaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // Area between high and low temperatures
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          Colors.orange.withOpacity(0.2),
          Colors.cyan.withOpacity(0.2),
        ],
      )
      ..style = PaintingStyle.fill;

    final highPath = Path();
    final lowPath = Path();
    final fillPath = Path();

    for (int i = 0; i < maxTemps.length; i++) {
      final x = i * dayWidth + (dayWidth / 2);
      final highY =
          (1 - ((maxTemps[i] - minTemp) / (maxTemp - minTemp))) * size.height;
      final lowY =
          (1 - ((minTemps[i] - minTemp) / (maxTemp - minTemp))) * size.height;

      if (i == 0) {
        highPath.moveTo(x, highY);
        lowPath.moveTo(x, lowY);
        fillPath.moveTo(x, highY);
      } else {
        highPath.lineTo(x, highY);
        lowPath.lineTo(x, lowY);
        fillPath.lineTo(x, highY);
      }
    }

    // Complete the fill path
    for (int i = maxTemps.length - 1; i >= 0; i--) {
      final x = i * dayWidth + (dayWidth / 2);
      final lowY =
          (1 - ((minTemps[i] - minTemp) / (maxTemp - minTemp))) * size.height;
      fillPath.lineTo(x, lowY);
    }

    // Close the fill path
    if (maxTemps.isNotEmpty) {
      fillPath.close();
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(highPath, highLinePaint);
    canvas.drawPath(lowPath, lowLinePaint);
  }

  void _drawTemperaturePoints(Canvas canvas, Size size) {
    final highDotPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    final lowDotPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final highTextStyle = ui.TextStyle(
      color: Colors.orange,
      fontSize: 12,
      fontWeight: ui.FontWeight.bold,
    );

    final lowTextStyle = ui.TextStyle(
      color: Colors.cyan,
      fontSize: 12,
      fontWeight: ui.FontWeight.bold,
    );

    for (int i = 0; i < maxTemps.length; i++) {
      final x = i * dayWidth + (dayWidth / 2);
      final highY =
          (1 - ((maxTemps[i] - minTemp) / (maxTemp - minTemp))) * size.height;
      final lowY =
          (1 - ((minTemps[i] - minTemp) / (maxTemp - minTemp))) * size.height;

      final isHighlighted = i == highlightedDay;

      // Draw high temperature dot
      canvas.drawCircle(
          Offset(x, highY), isHighlighted ? 5.0 : 4.0, highDotPaint);

      // Draw low temperature dot
      canvas.drawCircle(
          Offset(x, lowY), isHighlighted ? 5.0 : 4.0, lowDotPaint);

      // Add highlight outline for selected day
      if (isHighlighted) {
        canvas.drawCircle(Offset(x, highY), 5.0, highlightPaint);
        canvas.drawCircle(Offset(x, lowY), 5.0, highlightPaint);
      }

      // Draw high temperature value
      final highParagraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
      ))
        ..pushStyle(ui.TextStyle(
          color: Colors.orange,
          fontSize: 14, // Increased from 12
          fontWeight: ui.FontWeight.bold,
        ))
        ..addText('${maxTemps[i].round()}°');

      final highParagraph = highParagraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: dayWidth));

      // Draw low temperature value
      final lowParagraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
      ))
        ..pushStyle(ui.TextStyle(
          color: Colors.cyan,
          fontSize: 14, // Increased from 12
          fontWeight: ui.FontWeight.bold,
        ))
        ..addText('${minTemps[i].round()}°');

      final lowParagraph = lowParagraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: dayWidth));

      // Position temperature text
      final highTextY = highY - highParagraph.height - 5;
      final lowTextY = lowY + 5;

      canvas.drawParagraph(
          highParagraph, Offset(x - (highParagraph.width / 2), highTextY));

      canvas.drawParagraph(
          lowParagraph, Offset(x - (lowParagraph.width / 2), lowTextY));
    }
  }

  @override
  bool shouldRepaint(covariant DailyTemperatureChartPainter oldDelegate) =>
      minTemp != oldDelegate.minTemp ||
      maxTemp != oldDelegate.maxTemp ||
      highlightedDay != oldDelegate.highlightedDay;
}

class _WeeklyWeatherChartState extends State<WeeklyWeatherChart>
    with ChartOptimizationMixin, AutomaticKeepAliveClientMixin {
  // Add keep alive to prevent rebuilds when scrolling
  @override
  bool get wantKeepAlive => true;

  int? _highlightedDay;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to the very left initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Safely access data
    final List<String> dates = List<String>.from(widget.daily['time'] ?? []);
    if (dates.isEmpty) return const SizedBox.shrink(); // No data

    final List<num> maxTemps =
        List<num>.from(widget.daily['temperature_2m_max'] ?? []);
    final List<num> minTemps =
        List<num>.from(widget.daily['temperature_2m_min'] ?? []);
    final List<num> precipProbs =
        List<num>.from(widget.daily['precipitation_probability_max'] ?? []);

    if (maxTemps.isEmpty || minTemps.isEmpty)
      return const SizedBox.shrink(); // No temperature data

    // Prepare data for the chart
    final displayDates = dates;
    final displayMaxTemps = maxTemps.map((t) => t.toDouble()).toList();
    final displayMinTemps = minTemps.map((t) => t.toDouble()).toList();
    final displayPrecipProbs = precipProbs.isNotEmpty
        ? precipProbs.map((p) => p.toDouble()).toList()
        : List<double>.filled(displayDates.length, 0.0);

    // Calculate min and max temperature for scaling
    if (displayMaxTemps.isEmpty || displayMinTemps.isEmpty)
      return const SizedBox.shrink();

    double minTemp = displayMinTemps.reduce((a, b) => a < b ? a : b);
    double maxTemp = displayMaxTemps.reduce((a, b) => a > b ? a : b);

    // Add padding to min/max range
    final tempRange = maxTemp - minTemp;
    minTemp = minTemp - (tempRange * 0.1);
    maxTemp = maxTemp + (tempRange * 0.1);

    // FURTHER reduce chart height to address the 31px overflow
    final double chartHeight = tempRange < 10
        ? 140.0
        : (tempRange < 20 ? 160.0 : 190.0); // Reduced even more significantly

    // Keep same day width
    const double dayWidth = 90.0;

    // Calculate more conservative total content height needed
    final double totalContentHeight = chartHeight +
        120; // Changed from 70 to 120 to match hourly chart height

    return Card(
      elevation: 4,
      // Update margins to match the hourly chart exactly
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        // Update padding to match the hourly chart exactly
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row - Match hourly forecast styling exactly
            Text(
              'Weekly Forecast',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12), // Match hourly spacing
            // Use updated SizedBox height
            SizedBox(
              height: totalContentHeight, // Using updated height calculation
              child: ScrollConfiguration(
                behavior: MyCustomScrollBehavior(),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 6, // Increased from 4 to 6 to match hourly
                  radius: const Radius.circular(8),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      // Added padding wrapper to match hourly
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: displayDates.length * dayWidth,
                        height: totalContentHeight, // Match parent height
                        child: Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.expand,
                          children: [
                            // Weather icons - further reduce
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 30, // Reduced from 35
                              child: Row(
                                children:
                                    List.generate(displayDates.length, (i) {
                                  // ... existing weather icons code with smaller sizes ...
                                  final weatherCodes =
                                      widget.daily['weathercode'];
                                  int weatherCode = 0;
                                  if (weatherCodes != null &&
                                      i < weatherCodes.length) {
                                    // Sanitize the weather code
                                    weatherCode =
                                        WeatherUtils.sanitizeWeatherCode(
                                            weatherCodes[i]);
                                  }
                                  final forecastDate =
                                      DateTime.parse(displayDates[i]);

                                  return SizedBox(
                                    width: dayWidth,
                                    child: Center(
                                      child: buildWeatherIcon(
                                        weatherCode,
                                        forecastDate,
                                        20, // Reduced icon size from 24
                                        true,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            // Weather descriptions WITH BOXES like hourly
                            Positioned(
                              top: 30,
                              left: 0,
                              right: 0,
                              height: 20,
                              child: Row(
                                children:
                                    List.generate(displayDates.length, (i) {
                                  final weatherCodes =
                                      widget.daily['weathercode'];
                                  int weatherCode = 0;
                                  if (weatherCodes != null &&
                                      i < weatherCodes.length) {
                                    // Sanitize the weather code
                                    weatherCode =
                                        WeatherUtils.sanitizeWeatherCode(
                                            weatherCodes[i]);
                                  }
                                  final description =
                                      getWeatherDescription(weatherCode);

                                  return SizedBox(
                                    width: dayWidth,
                                    child: Center(
                                      child: WeatherDescriptionBox(
                                        description: description,
                                        isHighlighted: i == _highlightedDay,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            // Temperature chart - adjust position with MORE padding
                            Positioned(
                              top:
                                  60, // Increased from 50 to 60 to add more padding between descriptions and chart
                              left: 0,
                              right: 0,
                              height: chartHeight,
                              child: CustomPaint(
                                size: Size(displayDates.length * dayWidth,
                                    chartHeight),
                                painter: WeeklyTemperatureChartPainter(
                                  // ... existing parameters ...
                                  maxTemps: displayMaxTemps,
                                  minTemps: displayMinTemps,
                                  minTemp: minTemp,
                                  maxTemp: maxTemp,
                                  dayWidth: dayWidth,
                                  highlightedDay: _highlightedDay,
                                  temperatureUnit:
                                      widget.useMetric ? '°C' : '°F',
                                ),
                              ),
                            ),

                            // Precipitation indicators - MATCHING hourly styling
                            Positioned(
                              bottom: 20, // Adjusted position
                              left: 0,
                              right: 0,
                              height: 20, // Same as hourly
                              child: Row(
                                children:
                                    List.generate(displayDates.length, (i) {
                                  final probability =
                                      i < displayPrecipProbs.length
                                          ? displayPrecipProbs[i]
                                          : 0.0;

                                  // Skip if no precipitation probability
                                  if (probability <= 0)
                                    return SizedBox(width: dayWidth);

                                  // Define same blue gradient as hourly chart
                                  final List<Color> blueGradient = [
                                    const Color(
                                        0xFFBBDEFB), // Very light blue (for 1%)
                                    const Color(
                                        0xFF90CAF9), // Light blue (for 10%)
                                    const Color(
                                        0xFF64B5F6), // Light-medium blue (for 25%)
                                    const Color(
                                        0xFF42A5F5), // Medium blue (for 40%)
                                    const Color(
                                        0xFF2196F3), // Medium-strong blue (for 55%)
                                    const Color(
                                        0xFF1E88E5), // Strong blue (for 70%)
                                    const Color(
                                        0xFF1976D2), // Strong-dark blue (for 85%)
                                    const Color(
                                        0xFF1565C0), // Dark blue (for 95%)
                                    const Color(
                                        0xFF0D47A1), // Very dark blue (for 100%)
                                  ];

                                  // Calculate color based on probability
                                  final normalizedPos = (probability / 100) *
                                      (blueGradient.length - 1);
                                  final lowerIdx = normalizedPos.floor();
                                  final upperIdx = normalizedPos.ceil();
                                  final fraction = normalizedPos - lowerIdx;

                                  final color = Color.lerp(
                                    blueGradient[lowerIdx < blueGradient.length
                                        ? lowerIdx
                                        : blueGradient.length - 1],
                                    blueGradient[upperIdx < blueGradient.length
                                        ? upperIdx
                                        : blueGradient.length - 1],
                                    fraction,
                                  )!;

                                  final isHighlighted = i == _highlightedDay;

                                  return SizedBox(
                                    width: dayWidth,
                                    child: Center(
                                      child: PrecipitationIndicator(
                                        probability: probability,
                                        width: dayWidth,
                                        isHighlighted: isHighlighted,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            // Day labels - even smaller
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 12, // Reduced from 15
                              child: Row(
                                children:
                                    List.generate(displayDates.length, (i) {
                                  try {
                                    final dateTime =
                                        DateTime.parse(displayDates[i]);
                                    final isToday = dateTime.day ==
                                            DateTime.now().day &&
                                        dateTime.month == DateTime.now().month;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _highlightedDay =
                                              i == _highlightedDay ? null : i;
                                        });
                                      },
                                      child: Container(
                                        width: dayWidth,
                                        height: 15,
                                        decoration: BoxDecoration(
                                          color: i == _highlightedDay
                                              ? Colors.blue.withOpacity(0.15)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Center(
                                          child: Text(
                                            isToday
                                                ? 'Today'
                                                : DateFormat('E, M/d')
                                                    .format(dateTime),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: isToday ||
                                                      i == _highlightedDay
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isToday
                                                  ? Colors.blue
                                                  : i == _highlightedDay
                                                      ? Colors.blue.shade300
                                                      : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    return SizedBox(width: dayWidth);
                                  }
                                }),
                              ),
                            ),

                            // Enhanced tooltip matching hourly style - add if needed
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String getWeatherDescription(int code) {
  return WeatherUtils.getDescription(code);
}

class HourlyForecastItem extends StatelessWidget {
  final int hour;
  final double temperature;
  final int weatherCode;
  final bool isCurrentHour;
  final bool useMetric;

  const HourlyForecastItem({
    super.key,
    required this.hour,
    required this.temperature,
    required this.weatherCode,
    this.isCurrentHour = false,
    required this.useMetric,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = WeatherCodeMapper.getWeatherIcon(weatherCode);
    final description = WeatherCodeMapper.getWeatherDescription(weatherCode);

    // Force a minimum width for consistent spacing
    return SizedBox(
      width: 70, // Fixed width for each hourly entry
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${hour.toString().padLeft(2, '0')}:00',
            style: TextStyle(
              fontSize: 12,
              color: isCurrentHour ? Colors.white : Colors.grey.shade400,
              fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            iconData,
            size: 24,
            color: isCurrentHour ? Colors.white : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            '${temperature.round()}°${useMetric ? 'C' : 'F'}',
            style: TextStyle(
              fontSize: 14,
              color: isCurrentHour ? Colors.white : Colors.grey.shade300,
              fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          WeatherDescriptionBox(
            description: description,
            isHighlighted: isCurrentHour,
          ),
        ],
      ),
    );
  }
}
