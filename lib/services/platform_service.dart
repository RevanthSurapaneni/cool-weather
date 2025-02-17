import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class PlatformService {
  static Future<bool> checkLocationPermission() async {
    if (kIsWeb) {
      try {
        // Always request permission explicitly on web
        LocationPermission permission = await Geolocator.requestPermission();

        // For Firefox, we might need an additional check
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.unableToDetermine) {
          // Wait a moment before second attempt
          await Future.delayed(const Duration(milliseconds: 300));
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            print('Location services are disabled');
            return false;
          }
          permission = await Geolocator.requestPermission();
        }

        return permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
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
