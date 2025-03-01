import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class PlatformService {
  static Future<bool> checkLocationPermission() async {
    try {
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
      } else {
        // For web, just check if geolocation is available
        return true; // We'll handle actual permission in getCurrentPosition
      }
    } catch (e) {
      print('Permission check error: $e');
      return false;
    }
  }

  static Future<Position> getCurrentPosition() async {
    try {
      // For all platforms, use a lower timeout and accuracy for better web compatibility
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
    } on TimeoutException {
      throw Exception('Location request timed out. Please try again.');
    } catch (e) {
      if (kIsWeb) {
        print('Web location error: $e');
        throw Exception(
            'Please allow location access in your browser settings and try again.');
      } else {
        print('Location error: $e');
        throw Exception(
            'Could not get your location. Please check your device settings.');
      }
    }
  }
}
