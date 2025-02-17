import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class PlatformService {
  static Future<bool> checkLocationPermission() async {
    if (kIsWeb) {
      try {
        // First check if location services are enabled
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('Location services are disabled');
          return false;
        }

        // For web, especially Firefox, we need multiple attempts
        LocationPermission permission = await Geolocator.checkPermission();

        // If denied or not determined, request explicitly
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.unableToDetermine) {
          // Small delay before first request
          await Future.delayed(const Duration(milliseconds: 200));
          permission = await Geolocator.requestPermission();

          // If still denied, try one more time after a longer delay
          if (permission == LocationPermission.denied) {
            await Future.delayed(const Duration(seconds: 1));
            permission = await Geolocator.requestPermission();
          }
        }

        final result = permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
        print('Location permission result: $result');
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
        // First check if we have permission
        final hasPermission = await checkLocationPermission();
        if (!hasPermission) {
          throw Exception(
              'Please allow location access in your browser settings and try again.');
        }

        // Try to get position with multiple attempts
        for (int i = 0; i < 2; i++) {
          try {
            return await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
            ).timeout(
              Duration(seconds: i == 0 ? 10 : 20),
              onTimeout: () =>
                  throw TimeoutException('Location request timed out'),
            );
          } catch (e) {
            if (i == 1) rethrow; // If second attempt fails, throw error
            await Future.delayed(
                const Duration(seconds: 1)); // Wait before retry
          }
        }
        throw Exception('Failed to get location after multiple attempts');
      } catch (e) {
        if (e is TimeoutException) {
          throw Exception(
              'Location request timed out. Please try again or check your browser settings.');
        }
        throw Exception('Could not get location: ${e.toString()}');
      }
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }
}
