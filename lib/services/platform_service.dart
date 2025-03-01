import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class PlatformService {
  static final bool _permissionRequested = false;

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
      // For web production, try a simpler approach
      LocationPermission permission = await Geolocator.requestPermission();
      print('Web permission status: $permission');
      
      // Return true if we got any kind of permission
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

    try {
      // For web, just try to get position directly
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,  // Use low accuracy for better success rate
      ).timeout(
        const Duration(seconds: 5),  // Short timeout to avoid hanging
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );
    } catch (e) {
      print('Location error: $e');
      throw Exception('Please allow location access in your browser and try again.');
    }
  }
}
