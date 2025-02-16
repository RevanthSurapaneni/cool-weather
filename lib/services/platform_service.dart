import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class PlatformService {
  static Future<bool> checkLocationPermission() async {
    if (kIsWeb) {
      // Web-specific location check
      return await Geolocator.checkPermission() == LocationPermission.always;
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
      // Add timeout for web
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Location request timed out'),
      );
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }
}
