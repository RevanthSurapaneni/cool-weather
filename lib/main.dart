import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'services/weather_service.dart';
import 'widgets/forecast_widgets.dart';
import 'pages/settings_page.dart';
import 'services/preferences_service.dart';
import 'widgets/skeleton_widgets.dart';
import 'widgets/air_quality_widget.dart';
import 'services/platform_service.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _prefs = PreferencesService();
  bool _useMetric = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _useMetric = _prefs.getUseMetric();
    });
  }

  void _updateUnits(bool value) {
    setState(() {
      _useMetric = value;
    });
    _prefs.saveUseMetric(value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          surface: Colors.grey.shade900,
          background: const Color(0xFF121212), // Material 3 dark background
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.grey.shade900,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.grey.shade900,
        ),
        scaffoldBackgroundColor:
            const Color(0xFF121212), // Material 3 dark background
        textTheme: TextTheme(
          headlineSmall: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          titleMedium: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            color: Colors.blue,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF2196F3),
        ),
        inputDecorationTheme: const InputDecorationTheme(
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
  final _prefs = PreferencesService();

  @override
  void initState() {
    super.initState();
    _loadLastLocation();
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

  Future<void> _loadLastLocation() async {
    final lastLocation = _prefs.getLastLocation();
    if (lastLocation != null) {
      final location = Location.fromJson(lastLocation);
      await _selectLocation(location);
    }
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
      if (kIsWeb) {
        // Show "waiting for permission" message
        setState(() {
          _errorMessage = 'Requesting location access...';
        });

        // Give browser UI time to update
        await Future.delayed(const Duration(milliseconds: 100));

        final hasPermission = await PlatformService.checkLocationPermission();
        if (!hasPermission) {
          setState(() {
            _errorMessage = 'Location access denied. Please:\n'
                '1. Check the location icon in your browser\'s address bar\n'
                '2. Make sure location access is allowed\n'
                '3. Try again';
            _isLoading = false;
          });
          return;
        }

        // Clear the "waiting" message before getting position
        setState(() {
          _errorMessage = 'Getting location...';
        });
      }

      final position = await PlatformService.getCurrentPosition();

      if (!mounted) return;

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
      if (!mounted) return;

      print('Location error: $e');
      setState(() {
        _errorMessage = kIsWeb
            ? 'Location access failed. Please:\n'
                '1. Click the location icon in your browser\'s address bar\n'
                '2. Allow location access\n'
                '3. Refresh the page and try again'
            : 'Could not get location. Please check your location settings.';
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
      _isLoading = true;
    });
    await _fetchWeather();
    if (!isCurrent) {
      await _prefs.addRecentSearch(location.toJson());
    }
    _ignoreSearchUpdates = false;
    setState(() {
      _isLoading = false;
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
        useMetric: widget.useMetric,
      );
      AirQualityData? airQuality;
      try {
        airQuality = await WeatherService.getAirQuality(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        );
        print('Air Quality Data: $airQuality');
        weather.airQualityData = airQuality;
      } catch (e) {
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
              final oldMetric = widget.useMetric;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    useMetric: widget.useMetric,
                    onUnitChanged: widget.onUnitsChanged,
                  ),
                ),
              );

              // After settings page is closed, check if units actually changed
              if (oldMetric != widget.useMetric && mounted) {
                await _fetchWeather();
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
                child: TextFormField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.white),
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
                      borderSide: BorderSide(color: Colors.grey.shade600),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                  ),
                ),
              ),
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
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
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
              if (_isLoading) ...[
                const CurrentWeatherSkeleton(),
                const ForecastSkeleton(),
                const SizedBox(height: 16),
                const ForecastSkeleton(),
                const AirQualitySkeletonWidget(),
              ] else if (_weatherData != null) ...[
                CurrentWeatherWidget(
                  weatherData: _weatherData!,
                  lastUpdated: _lastUpdated,
                  isCurrentLocationSelected: _isCurrentLocationSelected,
                  selectedLocation: _selectedLocation,
                  useMetric: widget.useMetric,
                ),
                buildHourlyForecast(
                  _weatherData!.hourly,
                  _weatherData!.currentWeatherTime,
                  _weatherData!.sunrise,
                  _weatherData!.sunset,
                  _hourlyController,
                  widget.useMetric,
                ),
                const SizedBox(height: 16),
                buildDailyForecast(
                  _weatherData!.daily,
                  _dailyController,
                  widget.useMetric,
                ),
                if (_weatherData?.airQualityData != null)
                  AirQualityWidget(data: _weatherData!.airQualityData!),
              ],
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
