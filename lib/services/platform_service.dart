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
      print('Browser: ${isFirefox ? "Firefox" : "Other"}');

      // Check if we requested permission recently (within last 5 seconds)
      if (_lastPermissionRequest != null) {
        final timeSinceLastRequest =
            DateTime.now().difference(_lastPermissionRequest!);
        if (timeSinceLastRequest.inSeconds < 5) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine ||
          !_permissionRequested) {
        _lastPermissionRequest = DateTime.now();

        // Firefox specific: wait a moment before requesting
        if (isFirefox) {
          await Future.delayed(const Duration(milliseconds: 300));
        }

        permission = await Geolocator.requestPermission();
        _permissionRequested = true;

        if (isFirefox && permission == LocationPermission.denied) {
          await Future.delayed(const Duration(milliseconds: 500));
          permission = await Geolocator.requestPermission();
        }
      }

      final result = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      print('Permission status: $permission, Result: $result');
      return result;
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

      // Firefox: wait after permission before getting position
      if (isFirefox) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      Position? position;
      int attempts = 0;

      while (position == null && attempts < 3) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy:
                isFirefox ? LocationAccuracy.lowest : LocationAccuracy.medium,
            timeLimit: Duration(seconds: isFirefox ? 30 : 10),
          );
        } catch (e) {
          attempts++;
          if (attempts == 3) rethrow;
          await Future.delayed(const Duration(seconds: 1));
          print('Location attempt $attempts failed: $e');
        }
      }

      return position ??
          (throw Exception('Could not get location after multiple attempts'));
    } catch (e) {
      print('Get position error: $e');
      throw Exception(isFirefox
          ? 'Firefox location access failed. Please:\n'
              '1. Make sure you clicked "Allow" on the permission popup\n'
              '2. Check that location access is enabled in Firefox settings\n'
              '3. Refresh the page and try again'
          : 'Location access failed. Please allow location access and try again.');
    }
  }
}
