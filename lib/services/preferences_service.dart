import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PreferencesService {
  static const String _kUseMetricKey = 'use_metric';
  static const String _kLastLocationKey = 'last_location';
  static const String _kRecentSearchesKey = 'recent_searches';

  static final PreferencesService _instance = PreferencesService._internal();
  static late final SharedPreferences _prefs;

  factory PreferencesService() => _instance;

  PreferencesService._internal();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Unit Preferences
  Future<void> saveUseMetric(bool value) async {
    await _prefs.setBool(_kUseMetricKey, value);
  }

  bool getUseMetric() {
    return _prefs.getBool(_kUseMetricKey) ?? false;
  }

  // Location Preferences
  Future<void> saveLastLocation(Map<String, dynamic> location) async {
    await _prefs.setString(_kLastLocationKey, json.encode(location));
  }

  Map<String, dynamic>? getLastLocation() {
    final String? locationJson = _prefs.getString(_kLastLocationKey);
    if (locationJson == null) return null;
    try {
      return json.decode(locationJson);
    } catch (e) {
      return null;
    }
  }

  // Recent Searches
  Future<void> addRecentSearch(Map<String, dynamic> location) async {
    final List<String> searches =
        _prefs.getStringList(_kRecentSearchesKey) ?? [];
    final String locationJson = json.encode(location);

    // Remove if exists and add to front
    searches.remove(locationJson);
    searches.insert(0, locationJson);

    // Keep only last 5 searches
    if (searches.length > 5) {
      searches.removeLast();
    }

    await _prefs.setStringList(_kRecentSearchesKey, searches);
  }

  List<Map<String, dynamic>> getRecentSearches() {
    final List<String> searches =
        _prefs.getStringList(_kRecentSearchesKey) ?? [];
    return searches
        .map((s) {
          try {
            return json.decode(s) as Map<String, dynamic>;
          } catch (e) {
            return <String, dynamic>{};
          }
        })
        .where((map) => map.isNotEmpty)
        .toList();
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(_kRecentSearchesKey);
  }
}
