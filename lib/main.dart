import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'services/weather_service.dart';
import 'widgets/forecast_widgets.dart';
import 'pages/settings_page.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _useMetric = false;

  void _updateUnits(bool value) {
    setState(() {
      _useMetric = value;
    });
  }

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
        fontFamily: 'Poppins', // updated font family to Poppins
        // Reverted scaffoldBackgroundColor and appBarTheme to original settings
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: TextTheme(
          headlineSmall: const TextStyle(
            fontFamily: 'Poppins', // updated font family to Poppins
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          titleMedium: const TextStyle(
            fontFamily: 'Poppins', // updated font family to Poppins
            fontSize: 20,
            color: Colors.blue,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'Poppins', // updated font family to Poppins
            fontSize: 16,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'Poppins', // updated font family to Poppins
            fontSize: 14,
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF2196F3), // Keep cursor color blue
        ),
        inputDecorationTheme: const InputDecorationTheme(
          // This ensures consistent cursor color across all text fields
          focusColor: Color(0xFF2196F3),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFF2196F3),
              width: 2,
            ),
          ),
        ),
      ),
      home: WeatherHomePage(
        useMetric: _useMetric,
        onUnitsChanged: _updateUnits,
      ),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  final bool useMetric;
  final Function(bool) onUnitsChanged;

  const WeatherHomePage({
    super.key,
    required this.useMetric,
    required this.onUnitsChanged,
  });
  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  WeatherData? _weatherData;
  Location? _selectedLocation;
  bool _isLoading = false;
  String _errorMessage = '';
  List<Location> _locations = [];
  Timer? _debounce;
  DateTime? _lastUpdated;
  bool _isRefreshing = false;
  bool _isCurrentLocationSelected = false;
  bool _ignoreSearchUpdates = false;
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
              _errorMessage = '';
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
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
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 15));
      final location = Location(
        name:
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        latitude: position.latitude,
        longitude: position.longitude,
        country: '',
        state: '',
      );
      await _selectLocation(location, isCurrent: true);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectLocation(Location location,
      {bool isCurrent = false}) async {
    _ignoreSearchUpdates = true;
    _debounce?.cancel();
    setState(() {
      _selectedLocation = location;
      _isCurrentLocationSelected = isCurrent;
      _searchController.text = location.displayName;
      _locations = [];
      _errorMessage = '';
      _isLoading = true; // maintain loading while weather is fetched
    });
    await _fetchWeather();
    _ignoreSearchUpdates = false;
    setState(() {
      _isLoading = false; // now turn off loading after API call completes
    });
    FocusScope.of(context).unfocus();
  }

  void _onSearchChanged() {
    if (_ignoreSearchUpdates) return;
    if (_selectedLocation != null &&
        _searchController.text.trim() == _selectedLocation!.displayName) {
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final searchText = _searchController.text.trim();
      if (searchText.isNotEmpty && searchText.length > 2) {
        _searchLocation(searchText);
      } else {
        setState(() {
          _locations = [];
          _errorMessage = '';
        });
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.length <= 2) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _locations = [];
    });
    try {
      final locations = await WeatherService.geocodeLocation(query);
      setState(() {
        _locations = locations;
        if (locations.isEmpty && _selectedLocation == null) {
          _errorMessage = 'No locations found';
        }
      });
    } catch (e) {
      setState(() {
        if (_selectedLocation == null) _errorMessage = 'No locations found';
      });
    } finally {
      setState(() => _isLoading = false);
    }
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
        useMetric: widget.useMetric, // Pass the metric setting
      );
      AirQualityData? airQuality;
      try {
        airQuality = await WeatherService.getAirQuality(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        );
        print('Air Quality Data: $airQuality'); // Log the air quality data
        weather.airQualityData = airQuality;
      } catch (e) {
        // Log the error but don't stop the app from working
        print('Failed to fetch air quality data: $e');
      }
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
      _mainScrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
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
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshWeather,
          ),
          IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getCurrentLocation),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    useMetric: widget.useMetric,
                    onUnitChanged: widget.onUnitsChanged,
                  ),
                ),
              );
              if (mounted) {
                _fetchWeather(); // Refresh with new units
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _mainScrollController,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Replace TextField with TextFormField
                    TextFormField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: TextStyle(color: Colors.black87),
                      cursorWidth: 2.0,
                      cursorRadius: const Radius.circular(1),
                      decoration: InputDecoration(
                        labelText: 'Search Location',
                        hintText: 'Enter city name',
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    // Updated search results with Material 3 styling
                    if (_locations.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: _locations.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.5),
                            ),
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  _locations[index].displayName,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onTap: () => _selectLocation(_locations[index]),
                              );
                            },
                          ),
                        ),
                      ),
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
                CurrentWeatherWidget(
                  weatherData: _weatherData!,
                  lastUpdated: _lastUpdated,
                  isCurrentLocationSelected: _isCurrentLocationSelected,
                  selectedLocation: _selectedLocation,
                  useMetric: widget.useMetric, // Add this line
                ),
                buildHourlyForecast(
                  _weatherData!.hourly,
                  _weatherData!.currentWeatherTime,
                  _weatherData!.sunrise,
                  _weatherData!.sunset,
                  _hourlyController,
                  widget.useMetric, // Added useMetric parameter
                ),
                const SizedBox(height: 16),
                buildDailyForecast(
                  _weatherData!.daily,
                  _dailyController,
                  widget.useMetric, // Added useMetric parameter
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
