import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return false;
      }

      // Initial permission check
      LocationPermission permission = await Geolocator.checkPermission();
      print('Initial permission status: $permission');

      // If permission not determined or denied, request it
      if (!_permissionRequested &&
          (permission == LocationPermission.denied ||
              permission == LocationPermission.unableToDetermine)) {
        // Wait a moment before requesting
        await Future.delayed(const Duration(milliseconds: 200));
        permission = await Geolocator.requestPermission();
        _permissionRequested = true;
        print('Permission after request: $permission');
      }

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
      // Initial permission check without showing error
      final initialPermission = await Geolocator.checkPermission();
      if (initialPermission == LocationPermission.denied ||
          initialPermission == LocationPermission.unableToDetermine) {
        // Wait for the permission dialog
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Now check with proper error handling
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Please allow location access to continue');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      print('Get position error: $e');
      if (e is TimeoutException) {
        throw Exception('Location request timed out. Please try again.');
      }
      throw Exception(
          'Please enable location access in your browser settings.');
    }
  }
}
