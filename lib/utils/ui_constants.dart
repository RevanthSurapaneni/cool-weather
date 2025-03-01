import 'package:flutter/material.dart';

/// Central location for UI constants used across the app
class WeatherUIConstants {
  /// Standard precipitation color gradient used across the app
  static const List<Color> precipitationColors = [
    Color(0xFFBBDEFB), // Very light blue (for 1%)
    Color(0xFF90CAF9), // Light blue (for 10%)
    Color(0xFF64B5F6), // Light-medium blue (for 25%)
    Color(0xFF42A5F5), // Medium blue (for 40%)
    Color(0xFF2196F3), // Medium-strong blue (for 55%)
    Color(0xFF1E88E5), // Strong blue (for 70%)
    Color(0xFF1976D2), // Strong-dark blue (for 85%)
    Color(0xFF1565C0), // Dark blue (for 95%)
    Color(0xFF0D47A1), // Very dark blue (for 100%)
  ];

  /// Get color from precipitation gradient based on probability (0-100)
  static Color getPrecipitationColor(double probability,
      [double opacity = 1.0]) {
    if (probability <= 0) return precipitationColors.first.withOpacity(opacity);

    // Normalize probability to get position in gradient (0 to length-1)
    final normalizedPosition =
        (probability / 100) * (precipitationColors.length - 1);

    // Get the two colors to interpolate between
    final lowerIndex = normalizedPosition.floor();
    final upperIndex = normalizedPosition.ceil();

    // Get the exact fraction between the two colors
    final fraction = normalizedPosition - lowerIndex;

    // If we landed exactly on a color, return it
    if (lowerIndex == upperIndex) {
      return precipitationColors[lowerIndex].withOpacity(opacity);
    }

    // Interpolate between the two colors
    return Color.lerp(
      precipitationColors[lowerIndex],
      precipitationColors[upperIndex],
      fraction,
    )!
        .withOpacity(opacity);
  }

  /// Standard card decoration for forecast cards
  static BoxDecoration getForecastCardDecoration({bool isDark = true}) {
    return BoxDecoration(
      color: isDark ? Colors.grey.shade900 : Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Get temperature text style based on whether it's max or min temperature
  static TextStyle getTemperatureTextStyle({required bool isMax}) {
    return TextStyle(
      fontSize: isMax ? 14 : 13,
      fontWeight: isMax ? FontWeight.bold : FontWeight.w500,
      color: isMax ? Colors.orange : Colors.cyan,
    );
  }
}

/// Base class for temperature chart painters to share common methods
abstract class BaseTemperatureChartPainter extends CustomPainter {
  final double minTemp;
  final double maxTemp;
  final String temperatureUnit;

  BaseTemperatureChartPainter({
    required this.minTemp,
    required this.maxTemp,
    required this.temperatureUnit,
  });

  /// Draw common grid lines and temperature labels
  void drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines - 4 evenly spaced lines
    for (int i = 1; i < 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw temperature labels on left side
    drawTemperatureLabels(canvas, size);
  }

  /// Draw temperature labels on the y-axis
  void drawTemperatureLabels(Canvas canvas, Size size) {
    // Implementation provided by subclasses if needed
  }
}
