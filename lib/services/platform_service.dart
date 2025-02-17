import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class PlatformService {
  static Future<bool> checkLocationPermission() async {
    if (kIsWeb) {
      try {
        // First check if the service is enabled
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('Location services are disabled');
          return false;
        }

        // For Firefox, check current permission first
        LocationPermission permission = await Geolocator.checkPermission();

        // If we don't have permission yet, request it
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.unableToDetermine) {
          // Firefox needs a user interaction before requesting permission
          await Future.delayed(const Duration(milliseconds: 100));
          permission = await Geolocator.requestPermission();
        }

        final result = permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
        print('Location permission check result: $permission');
        return result;
      } catch (e) {
        print('Location permission check failed: $e');
        return false;
      }
    } else {
      // Mobile/desktop location check
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
  }

  static Future<Position> getCurrentPosition() async {
    if (kIsWeb) {
      try {
        // For Firefox, we need to be more patient
        return await Geolocator.getCurrentPosition(
          desiredAccuracy:
              LocationAccuracy.low, // Lower accuracy for faster response
          timeLimit: const Duration(seconds: 10), // Add explicit time limit
        );
      } catch (e) {
        print('Location error: $e');
        throw Exception(
            'Could not get location. Please ensure location access is enabled in your browser settings.');
      }
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }
}
