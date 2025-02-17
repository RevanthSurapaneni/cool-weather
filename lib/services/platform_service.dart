import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:html' as html;

class PlatformService {
  static bool _permissionRequested = false;
  static DateTime? _lastPermissionRequest;

  static Future<bool> checkLocationPermission() async {
    if (!kIsWeb) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    }

    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      final isFirefox = userAgent.contains('firefox');
      print(
          'Checking location permission for: ${isFirefox ? "Firefox" : "Other browser"}');

      // For Firefox, we need to explicitly check if geolocation is available
      if (isFirefox) {
        if (html.window.navigator.geolocation == null) {
          print('Geolocation API not available');
          return false;
        }
      }

      // First check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return false;
      }

      if (!_permissionRequested) {
        print('Requesting permission for the first time');
        _permissionRequested = true;

        // For Firefox, use a longer initial delay
        if (isFirefox) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        final permission = await Geolocator.requestPermission();
        print('Initial permission result: $permission');

        return permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
      }

      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Permission check error: $e');
      return false;
    }
  }

  static Future<Position> getCurrentPosition() async {
    if (!kIsWeb) {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    }

    final userAgent = html.window.navigator.userAgent.toLowerCase();
    final isFirefox = userAgent.contains('firefox');

    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission not granted');
      }

      // For Firefox, we need more attempts with longer timeouts
      final maxAttempts = isFirefox ? 5 : 3;
      final timeoutSeconds = isFirefox ? 60 : 20;

      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          print('Location attempt $attempt of $maxAttempts');

          // Wait a bit longer between attempts for Firefox
          if (attempt > 1 && isFirefox) {
            await Future.delayed(const Duration(seconds: 2));
          }

          return await Geolocator.getCurrentPosition(
            desiredAccuracy:
                isFirefox ? LocationAccuracy.reduced : LocationAccuracy.medium,
            timeLimit: Duration(seconds: timeoutSeconds),
          );
        } catch (e) {
          print('Attempt $attempt failed: $e');
          if (attempt == maxAttempts) rethrow;
        }
      }

      throw Exception('Failed to get location after $maxAttempts attempts');
    } catch (e) {
      print('Get position error: $e');
      throw Exception(isFirefox
          ? 'Firefox location request failed. Please ensure:\n'
              '1. You allowed location access in the popup\n'
              '2. Location is enabled in Firefox settings\n'
              '3. Try refreshing the page'
          : 'Location access failed. Please check your settings and try again.');
    }
  }
}
