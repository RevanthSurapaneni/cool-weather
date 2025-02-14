import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'services/weather_service.dart';
import 'widgets/forecast_widgets.dart';

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
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall:
              TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});
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
        if (permission == LocationPermission.denied)
          throw Exception('Location permissions denied');
      }
      if (permission == LocationPermission.deniedForever)
        throw Exception('Location permissions permanently denied');
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
      _selectLocation(location, isCurrent: true);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectLocation(Location location, {bool isCurrent = false}) {
    _ignoreSearchUpdates = true;
    _debounce?.cancel();
    setState(() {
      _selectedLocation = location;
      _isCurrentLocationSelected = isCurrent;
      _searchController.text = location.displayName;
      _locations = [];
      _errorMessage = '';
    });
    _fetchWeather().whenComplete(() => _ignoreSearchUpdates = false);
    FocusScope.of(context).unfocus();
  }

  void _onSearchChanged() {
    if (_ignoreSearchUpdates) return;
    if (_selectedLocation != null &&
        _searchController.text.trim() == _selectedLocation!.displayName) return;
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
                    TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search for a location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    if (_locations.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: _locations.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_locations[index].displayName),
                            onTap: () => _selectLocation(_locations[index]),
                          );
                        },
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
                ),
                if (_lastUpdated != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Updated: ${DateFormat.jm().format(_lastUpdated!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                buildHourlyForecast(
                  _weatherData!.hourly,
                  _weatherData!.currentWeatherTime,
                  _weatherData!.sunrise,
                  _weatherData!.sunset,
                  _hourlyController,
                ),
                const SizedBox(height: 16),
                buildDailyForecast(_weatherData!.daily, _dailyController),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
