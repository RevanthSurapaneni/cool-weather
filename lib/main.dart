import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' show min;
import 'package:weather_icons/weather_icons.dart';
import 'package:geolocator/geolocator.dart';

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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
      home: const WeatherHomePage(),
    );
  }
}

// Replace WeatherService class with this version using http package
class WeatherService {
  static const String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  static Future<List<Location>> geocodeLocation(String query) async {
    final response = await http.get(Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$query&count=10&language=en'));

    if (response.statusCode == 200) {
      // Cast results as a List if not null
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
        // Return empty list instead of fallback so we know reverse geocoding failed
        return [];
      }
      return results.map((e) => Location.fromJson(e)).toList();
    } else {
      throw Exception('Failed to reverse geocode location');
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
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      country: json['country'],
      state: json['admin1'],
    );
  }

  String get displayName {
    if (state?.isNotEmpty ?? false) {
      return '$name, $state, $country';
    }
    return '$name, $country';
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
  final DateTime currentWeatherTime; // Add this field

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
    required this.currentWeatherTime, // Add this field
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final todayIndex = 0;

    // Find the current hour's index
    final List<String> hourlyTime = List<String>.from(json['hourly']['time']);
    final currentHourString =
        DateTime(now.year, now.month, now.day, now.hour).toIso8601String();
    final currentIndex = hourlyTime.indexOf(currentHourString);

    try {
      return WeatherData(
        currentTemp: json['current_weather']['temperature'].toDouble(),
        currentWindSpeed: json['current_weather']['windspeed'].toDouble(),
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
            : json['current_weather']['temperature'].toDouble(),
        windDirection: json['current_weather']['winddirection'] as int,
        isDay: currentIndex != -1
            ? (json['hourly']['is_day'][currentIndex] ?? 1) == 1
            : true,
        currentWeatherTime:
            DateTime.parse(json['current_weather']['time']), // Add this field
      );
    } catch (e) {
      throw Exception('Failed to parse weather data: $e');
    }
  }

  String getWindDirection() {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return directions[((windDirection + 22.5) % 360) ~/ 45];
  }

  bool isDaytime() {
    final now = DateTime.now();
    return now.isAfter(sunrise) && now.isBefore(sunset);
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  WeatherData? _weatherData;
  Location? _selectedLocation;
  bool _isLoading = false;
  String _errorMessage = '';
  List<Location> _locations = [];
  Timer? _debounce;
  DateTime? _lastUpdated;
  bool _isRefreshing = false;
  bool _isCurrentLocationSelected = false;

  final ScrollController _hourlyController = ScrollController();
  final ScrollController _dailyController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _locations = [];
              if (_selectedLocation != null) {
                _errorMessage = '';
              }
            });
          }
        });
      }
    });
    // Removed auto location fetching here.
    // _getCurrentLocation();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _hourlyController.dispose();
    _dailyController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Check if location services are enabled.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage =
            'Location services are disabled. Please enable them in settings.';
        _isLoading = false;
      });
      return;
    }

    // Check and request location permissions.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage =
              'Location permissions are denied. Please enable them in settings.';
          _isLoading = false;
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage =
            'Location permissions are permanently denied. Enable permissions from settings.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Use medium accuracy and a timeout to prevent long waits.
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Timed out waiting for location');
        },
      );

      // Create a Location object using the coordinates.
      final location = Location(
        name:
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        latitude: position.latitude,
        longitude: position.longitude,
        country: '',
        state: '',
      );

      _selectLocation(location, isCurrent: true);
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Location request timed out. Try again later.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectLocation(Location location, {bool isCurrent = false}) {
    setState(() {
      _selectedLocation = location;
      _isCurrentLocationSelected = isCurrent;
      // Always update search field with whatever the location returns.
      _searchController.text = location.displayName;
      _locations = [];
      _errorMessage = '';
    });
    _fetchWeather();
    // Dismiss the keyboard.
    FocusScope.of(context).unfocus();
  }

  Future<void> _fetchWeather() async {
    if (_selectedLocation == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final weather = await WeatherService.getWeather(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      setState(() {
        _weatherData = weather;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to fetch weather data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshWeather() async {
    if (_selectedLocation == null) return;

    setState(() => _isRefreshing = true);
    await _fetchWeather();
    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _lastUpdated = DateTime.now();
      });
      _mainScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final searchText = _searchController.text.trim();
      // Only search if there's actual text and length > 2
      if (searchText.isNotEmpty && searchText.length > 2) {
        _searchLocation(searchText);
      } else {
        // Clear locations but don't show error if the field is empty
        setState(() {
          _locations = [];
          _errorMessage = '';
        });
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    // Don't search if the text is empty or too short
    if (query.trim().length <= 2) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _locations = [];
    });

    try {
      final locations = await WeatherService.geocodeLocation(query);
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _locations = locations;
        // Only show error if user hasn't selected a location
        if (locations.isEmpty && _selectedLocation == null) {
          _errorMessage = 'No locations found';
        } else {
          _errorMessage = '';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Only show error if user hasn't selected a location
        if (_selectedLocation == null) {
          _errorMessage = 'No locations found';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Revised _buildWeatherIcon method comparing only the hours for sunrise/sunset.
  Widget _buildWeatherIcon(
    int code, [
    DateTime? dateTime,
    double? size = 40,
    bool forceDay = false,
    DateTime? sunrise,
    DateTime? sunset,
  ]) {
    bool isNight;
    if (forceDay || dateTime == null) {
      isNight = false;
    } else if (sunrise != null && sunset != null) {
      final int forecastHour = dateTime.hour;
      final int sunriseHour = sunrise.hour;
      final int sunsetHour = sunset.hour;
      // If the forecast hour is before sunrise or after sunset, it's night.
      isNight = forecastHour < sunriseHour || forecastHour > sunsetHour;
    } else {
      isNight = dateTime.hour >= 18 || dateTime.hour < 6;
    }
    final double iconSize = size ?? 40.0;

    switch (code) {
      case 0: // Clear sky
        return BoxedIcon(
          isNight ? WeatherIcons.night_clear : WeatherIcons.day_sunny,
          size: iconSize,
          color: isNight ? const Color(0xFF486581) : const Color(0xFFFF9D00),
        );
      case 1: // Mainly clear
      case 2: // Partly cloudy
        return BoxedIcon(
          isNight
              ? WeatherIcons.night_alt_partly_cloudy
              : WeatherIcons.day_cloudy_high,
          size: iconSize,
          color: isNight ? const Color(0xFF486581) : const Color(0xFF62B2FF),
        );
      case 3: // Overcast
        return BoxedIcon(
          WeatherIcons.cloudy,
          size: iconSize,
          color: isNight ? const Color(0xFF486581) : const Color(0xFF62B2FF),
        );
      case 45: // Foggy
      case 48: // Depositing rime fog
        return BoxedIcon(
          WeatherIcons.fog,
          size: iconSize,
          color: isNight ? const Color(0xFF7A8B9A) : const Color(0xFF9FB3C8),
        );
      case 51: // Light drizzle
        return BoxedIcon(
          WeatherIcons.sprinkle,
          size: iconSize,
          color: isNight ? const Color(0xFF3178C6) : const Color(0xFF4098D7),
        );
      case 53: // Moderate drizzle
      case 55: // Dense drizzle
        return BoxedIcon(
          WeatherIcons.rain_mix,
          size: iconSize,
          color: isNight ? const Color(0xFF3178C6) : const Color(0xFF4098D7),
        );
      case 61: // Slight rain
      case 63: // Moderate rain
      case 65: // Heavy rain
        return BoxedIcon(
          WeatherIcons.rain,
          size: iconSize,
          color: isNight ? const Color(0xFF25507A) : const Color(0xFF3178C6),
        );
      case 71: // Slight snow
      case 73: // Moderate snow
      case 75: // Heavy snow
      case 77: // Snow grains
        return BoxedIcon(
          WeatherIcons.snow,
          size: iconSize,
          color: isNight ? const Color(0xFF607D8B) : const Color(0xFF90CDF4),
        );
      case 80: // Slight rain showers
      case 81: // Moderate rain showers
        return BoxedIcon(
          WeatherIcons.showers,
          size: iconSize,
          color: isNight ? const Color(0xFF1F3E5A) : const Color(0xFF2C5282),
        );
      case 82: // Violent rain showers
        return BoxedIcon(
          WeatherIcons.storm_showers,
          size: iconSize,
          color: isNight ? const Color(0xFF1F3E5A) : const Color(0xFF2C5282),
        );
      case 85: // Slight snow showers
      case 86: // Heavy snow showers
        return BoxedIcon(
          WeatherIcons.snow,
          size: iconSize,
          color: isNight ? const Color(0xFF607D8B) : const Color(0xFF90CDF4),
        );
      case 95: // Thunderstorm
      case 96: // Thunderstorm with slight hail
      case 99: // Thunderstorm with heavy hail
        return BoxedIcon(
          WeatherIcons.thunderstorm,
          size: iconSize,
          color: isNight ? const Color(0xFF553C7B) : const Color(0xFF805AD5),
        );
      default:
        return BoxedIcon(
          WeatherIcons.na,
          size: iconSize,
          color: Colors.grey,
        );
    }
  }

  Widget _buildLocationSuggestions() {
    if (_locations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 4,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        margin: const EdgeInsets.only(top: 8),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: _locations.length,
          itemBuilder: (context, index) => Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectLocation(_locations[index], isCurrent: false),
              hoverColor: Colors.blue.withOpacity(0.1),
              splashColor: Colors.blue.withOpacity(0.2),
              highlightColor: Colors.blue.withOpacity(0.1),
              child: ListTile(
                title: Text(_locations[index].displayName),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                hoverColor: Colors.blue.withOpacity(0.1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentWeather() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    // Calculate current hour's index from hourly data.
    String rainChance = '0%';
    String feelsLikeTemp = 'N/A';
    if (_weatherData != null && _weatherData!.hourly['time'] != null) {
      final List<String> timeList =
          List<String>.from(_weatherData!.hourly['time']);
      final List<dynamic> precipitation =
          _weatherData!.hourly['precipitation_probability'];
      final List<dynamic> apparentTemps =
          _weatherData!.hourly['apparent_temperature'];
      final DateTime locationNow = _weatherData!.currentWeatherTime;
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
      margin: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (_lastUpdated != null)
                  Text(
                    'Updated: ${DateFormat.jm().format(_lastUpdated!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _isCurrentLocationSelected
                  ? 'Current Location'
                  : _selectedLocation?.displayName ?? '',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.blue[800]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _buildWeatherIcon(
                    _weatherData!.currentWeatherCode,
                    _weatherData!.currentWeatherTime,
                    60,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Text(
                      '${_weatherData!.currentTemp.toStringAsFixed(1)}°F',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 40 : 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      weatherDescriptions[_weatherData!.currentWeatherCode] ??
                          'Unknown',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildWeatherDetail(
                  Icons.thermostat,
                  'Feels like',
                  feelsLikeTemp,
                ),
                _buildWeatherDetail(
                  Icons.wb_sunny,
                  'UV Index',
                  _getUVDescription(_weatherData!.uvIndex),
                ),
                _buildWeatherDetail(
                  Icons.navigation,
                  'Wind',
                  '${_weatherData!.currentWindSpeed.round()} mph ${_weatherData!.getWindDirection()}',
                ),
                _buildWeatherDetail(
                  Icons.water_drop,
                  'Rain chance',
                  rainChance,
                ),
                _buildWeatherDetail(
                  Icons.wb_twilight,
                  'Sunrise',
                  DateFormat('h:mm a').format(_weatherData!.sunrise),
                ),
                _buildWeatherDetail(
                  Icons.nights_stay,
                  'Sunset',
                  DateFormat('h:mm a').format(_weatherData!.sunset),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    IconData actualIcon = icon;
    if (label == 'Wind') {
      actualIcon = WeatherIcons.strong_wind; // Replace with wind icon
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(actualIcon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getUVDescription(double uvIndex) {
    if (uvIndex <= 2) return 'Low';
    if (uvIndex <= 5) return 'Moderate';
    if (uvIndex <= 7) return 'High';
    if (uvIndex <= 10) return 'Very High';
    return 'Extreme';
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const Spacer(),
          // Optionally add an icon or action button here.
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
    final List<String> timeList =
        List<String>.from(_weatherData!.hourly['time']);
    final List<dynamic> temps = _weatherData!.hourly['temperature_2m'];
    final List<dynamic> codes = _weatherData!.hourly['weathercode'];
    final List<dynamic>? precipitation =
        _weatherData!.hourly['precipitation_probability'];

    // Use the location's current time from the API data.
    final locationNow = _weatherData!.currentWeatherTime;
    final currentHour = DateTime(
        locationNow.year, locationNow.month, locationNow.day, locationNow.hour);

    // Match using the API's timestamps (assumed to be in the local time of the location)
    final int currentHourIndex = timeList.indexWhere((timeStr) {
      final forecastTime = DateTime.parse(timeStr);
      final forecastHour = DateTime(
        forecastTime.year,
        forecastTime.month,
        forecastTime.day,
        forecastTime.hour,
      );
      return forecastHour == currentHour;
    });
    final int startIndex = (currentHourIndex == -1) ? 0 : currentHourIndex;
    final int itemCount = min(24, timeList.length - startIndex);

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
            controller: _hourlyController,
            child: ListView.builder(
              controller: _hourlyController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                final int actualIndex = startIndex + index;
                // Parse forecast time (without converting to device local time).
                final DateTime forecastTime =
                    DateTime.parse(timeList[actualIndex]);
                final bool isCurrentHour = index == 0;
                final int weatherCode = codes[actualIndex] as int;
                final String weatherDescription =
                    weatherDescriptions[weatherCode] ?? 'Unknown';

                return Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrentHour ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        isCurrentHour
                            ? 'Now'
                            : DateFormat('ha').format(forecastTime),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrentHour
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      _buildWeatherIcon(
                        weatherCode,
                        forecastTime,
                        40,
                        false,
                        _weatherData!.sunrise,
                        _weatherData!.sunset,
                      ),
                      Text(
                        weatherDescription,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      if (precipitation != null &&
                          actualIndex < precipitation.length)
                        Text(
                          '${precipitation[actualIndex].round()}%',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      Text(
                        '${temps[actualIndex].round()}°',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyForecast() {
    final List<dynamic> time = _weatherData!.daily['time'];
    final List<dynamic> maxTemps = _weatherData!.daily['temperature_2m_max'];
    final List<dynamic> minTemps = _weatherData!.daily['temperature_2m_min'];
    final List<dynamic> codes = _weatherData!.daily['weathercode'];
    final List<dynamic>? precipPercents =
        _weatherData!.daily['precipitation_probability_max'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220, // Increased height to provide more vertical space
          child: Scrollbar(
            thumbVisibility: true,
            controller: _dailyController,
            child: ListView.builder(
              controller: _dailyController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: time.length,
              itemBuilder: (context, index) {
                final DateTime date = DateTime.parse(time[index]);
                final bool isToday = date.day == DateTime.now().day;
                final int weatherCode = codes[index] as int;
                final String weatherDescription =
                    weatherDescriptions[weatherCode] ?? 'Unknown';
                final String precipText =
                    (precipPercents != null && index < precipPercents.length)
                        ? '${precipPercents[index].round()}%'
                        : '0%';

                return Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        isToday ? 'Today' : DateFormat('E').format(date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      _buildWeatherIcon(weatherCode, date, 40, true),
                      Text(
                        weatherDescription,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        precipText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${maxTemps[index].round()}°',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${minTemps[index].round()}°',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _isLoading
          ? Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshWeather,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _mainScrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ... existing widgets such as search bar, location suggestions, etc.
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              labelText: 'Search Location',
                              hintText: 'Enter city name',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _locations = [];
                                          _errorMessage = '';
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (value) {
                              if (value.trim().length > 2) {
                                _searchLocation(value.trim());
                                // Dismiss the keyboard after submission.
                                FocusScope.of(context).unfocus();
                              }
                            },
                          ),
                          ElevatedButton(
                            onPressed: _getCurrentLocation,
                            child: const Text('Use Current Location'),
                          ),
                          _buildLocationSuggestions(),
                        ],
                      ),
                    ),
                    if (_isLoading) const LinearProgressIndicator(),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_weatherData != null) ...[
                      _buildCurrentWeather(),
                      _buildSectionHeader('Hourly Forecast'),
                      _buildHourlyForecast(),
                      _buildSectionHeader('7-Day Forecast'),
                      _buildDailyForecast(),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Add this extension method for responsive sizing
extension ContextExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isSmallScreen => screenWidth < 600;
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1200;
  bool get isLargeScreen => screenWidth >= 1200;
}
