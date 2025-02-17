import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:html' as html;

class PlatformService {
  static bool _permissionRequested = false;

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
      // For web browsers
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return false;
      }

      // Check if browser is Firefox
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      final isFirefox = userAgent.contains('firefox');
      print('Browser: ${isFirefox ? "Firefox" : "Other"}');

      LocationPermission permission = await Geolocator.checkPermission();

      if (!_permissionRequested) {
        // First time permission request
        await Future.delayed(const Duration(milliseconds: 200));
        permission = await Geolocator.requestPermission();
        _permissionRequested = true;

        if (isFirefox && permission == LocationPermission.denied) {
          // Firefox might need an extra moment
          await Future.delayed(const Duration(milliseconds: 500));
          permission = await Geolocator.requestPermission();
        }
      }

      final result = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      print('Permission result: $permission');
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

      if (isFirefox) {
        // Firefox needs more time and lower accuracy
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 20),
        );
      } else {
        // Other browsers
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      }
    } catch (e) {
      print('Get position error: $e');
      throw Exception(isFirefox
          ? 'Firefox location access failed. Please check your browser settings and try again.'
          : 'Location access failed. Please allow location access and try again.');
    }
  }
}
