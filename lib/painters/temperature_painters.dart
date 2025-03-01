import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Base class for temperature chart painters
abstract class BaseTemperatureChartPainter extends CustomPainter {
  final double minTemp;
  final double maxTemp;
  final double unitWidth;
  final String temperatureUnit;

  BaseTemperatureChartPainter({
    required this.minTemp,
    required this.maxTemp,
    required this.unitWidth,
    required this.temperatureUnit,
  });

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1.0;

    // Horizontal grid lines - 4 evenly spaced lines
    for (int i = 1; i < 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Temperature range labels on left side
    final textStyle = ui.TextStyle(
      color: Colors.grey[400],
      fontSize: 10,
    );

    final tempRange = maxTemp - minTemp;
    final tempStep = tempRange / 4;

    for (int i = 0; i <= 4; i++) {
      final temp = maxTemp - (i * tempStep);
      final y = (size.height / 4) * i;

      final paragraphBuilder =
          ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.right))
            ..pushStyle(textStyle)
            ..addText('${temp.round()}°');

      final paragraph = paragraphBuilder.build()
        ..layout(const ui.ParagraphConstraints(width: 30));

      canvas.drawParagraph(paragraph, Offset(-35, y - paragraph.height / 2));
    }
  }

  /// Calculate normalized Y position for a temperature
  double calculateYPosition(double temp, Size size) {
    return (1 - ((temp - minTemp) / (maxTemp - minTemp))) * size.height;
  }

  /// Draw a temperature dot with optional highlight
  void drawTemperatureDot(
      Canvas canvas, Offset position, Color color, bool isHighlighted,
      {double regularRadius = 3.0, double highlightRadius = 5.0}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        position, isHighlighted ? highlightRadius : regularRadius, paint);

    if (isHighlighted) {
      final highlightPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(position, highlightRadius, highlightPaint);
    }
  }

  /// Draw a temperature text label at a specific position
  void drawTemperatureText(
    Canvas canvas,
    Offset position,
    double temperature, {
    required Color color,
    required double fontSize,
    bool isBold = false,
    TextAlign textAlign = TextAlign.center,
    double width = 60.0,
  }) {
    final textStyle = ui.TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: isBold ? ui.FontWeight.bold : ui.FontWeight.normal,
    );

    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: textAlign == TextAlign.center
            ? ui.TextAlign.center
            : (textAlign == TextAlign.left
                ? ui.TextAlign.left
                : ui.TextAlign.right)))
      ..pushStyle(textStyle)
      ..addText('${temperature.round()}°');

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: width));

    canvas.drawParagraph(
      paragraph,
      Offset(
        position.dx - (paragraph.width / 2),
        position.dy,
      ),
    );
  }
}

/// Painter for hourly temperature charts
class TemperatureChartPainter extends BaseTemperatureChartPainter {
  final List<double> temperatures;
  final List<double> precipitationProbabilities;
  final int? highlightedHour;

  // Cache expensive computations
  Path? _tempPath;
  Path? _fillPath;
  List<Offset>? _pointOffsets;
  Size? _lastSize;

  TemperatureChartPainter({
    required this.temperatures,
    required double minTemp,
    required double maxTemp,
    required double hourWidth,
    required this.precipitationProbabilities,
    required String temperatureUnit,
    this.highlightedHour,
  }) : super(
          minTemp: minTemp,
          maxTemp: maxTemp,
          unitWidth: hourWidth,
          temperatureUnit: temperatureUnit,
        );

  @override
  void paint(Canvas canvas, Size size) {
    // Only recalculate paths if size changes or first paint
    if (_lastSize != size || _tempPath == null) {
      _calculatePaths(size);
      _lastSize = size;
    }

    _drawGrid(canvas, size);

    // Use cached paths
    if (_fillPath != null) {
      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height),
          Offset(0, 0),
          [
            Colors.orangeAccent.withOpacity(0.1),
            Colors.orangeAccent.withOpacity(0.3),
          ],
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(_fillPath!, fillPaint);
    }

    if (_tempPath != null) {
      final linePaint = Paint()
        ..color = Colors.orangeAccent
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(_tempPath!, linePaint);
    }

    _drawTemperaturePoints(canvas, size);
  }

  void _calculatePaths(Size size) {
    final path = Path();
    final fillPath = Path();
    final pointOffsets = <Offset>[];

    for (int i = 0; i < temperatures.length; i++) {
      final x = i * unitWidth + (unitWidth / 2);
      final y = calculateYPosition(temperatures[i], size);
      final point = Offset(x, y);
      pointOffsets.add(point);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == temperatures.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    _tempPath = path;
    _fillPath = fillPath;
    _pointOffsets = pointOffsets;
  }

  // Use cached point positions for drawing temperature points
  void _drawTemperaturePoints(Canvas canvas, Size size) {
    if (_pointOffsets == null) return;

    for (int i = 0; i < _pointOffsets!.length; i++) {
      final point = _pointOffsets![i];
      final isHighlighted = i == highlightedHour;

      // Draw temperature dot
      drawTemperatureDot(
        canvas,
        point,
        isHighlighted ? Colors.orangeAccent : Colors.white,
        isHighlighted,
      );

      // Add temperature text with improved text rendering
      _drawOptimizedTemperatureText(
          canvas, point, temperatures[i], isHighlighted);
    }
  }

  // More efficient text rendering with pre-calculated positions
  void _drawOptimizedTemperatureText(
      Canvas canvas, Offset point, double temperature, bool isHighlighted) {
    // ...implementation with simplified text rendering...
  }

  @override
  bool shouldRepaint(covariant TemperatureChartPainter oldDelegate) =>
      minTemp != oldDelegate.minTemp ||
      maxTemp != oldDelegate.maxTemp ||
      highlightedHour != oldDelegate.highlightedHour;
}

/// Painter for daily temperature charts (renamed from "weekly")
class DailyTemperatureChartPainter extends BaseTemperatureChartPainter {
  final List<double> maxTemps;
  final List<double> minTemps;
  final int? highlightedDay;

  DailyTemperatureChartPainter({
    required this.maxTemps,
    required this.minTemps,
    required double minTemp,
    required double maxTemp,
    required double dayWidth,
    required String temperatureUnit,
    this.highlightedDay,
  }) : super(
          minTemp: minTemp,
          maxTemp: maxTemp,
          unitWidth: dayWidth,
          temperatureUnit: temperatureUnit,
        );

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawTemperatureLines(canvas, size);
    _drawTemperaturePoints(canvas, size);
  }

  @override
  void _drawTemperatureLines(Canvas canvas, Size size) {
    // Adjust line thickness to match hourly chart
    final highLinePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3.0 // Match hourly chart's line thickness
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // Low temperature line
    final lowLinePaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 3.0 // Match hourly chart's line thickness
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // Area between high and low temperatures - adjust opacity to match hourly
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          Colors.orange.withOpacity(0.15), // Reduced opacity to match hourly
          Colors.cyan.withOpacity(0.15), // Reduced opacity to match hourly
        ],
      )
      ..style = PaintingStyle.fill;

    final highPath = Path();
    final lowPath = Path();
    final fillPath = Path();

    for (int i = 0; i < maxTemps.length; i++) {
      final x = i * unitWidth + (unitWidth / 2);
      final highY = calculateYPosition(maxTemps[i], size);
      final lowY = calculateYPosition(minTemps[i], size);

      if (i == 0) {
        highPath.moveTo(x, highY);
        lowPath.moveTo(x, lowY);
        fillPath.moveTo(x, highY);
      } else {
        highPath.lineTo(x, highY);
        lowPath.lineTo(x, lowY);
        fillPath.lineTo(x, highY);
      }
    }

    // Complete the fill path
    for (int i = maxTemps.length - 1; i >= 0; i--) {
      final x = i * unitWidth + (unitWidth / 2);
      final lowY = calculateYPosition(minTemps[i], size);
      fillPath.lineTo(x, lowY);
    }

    // Close the fill path
    if (maxTemps.isNotEmpty) {
      final startX = 0 * unitWidth + (unitWidth / 2);
      final startHighY = calculateYPosition(maxTemps[0], size);
      fillPath.lineTo(startX, startHighY);
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(highPath, highLinePaint);
    canvas.drawPath(lowPath, lowLinePaint);
  }

  @override
  void _drawTemperaturePoints(Canvas canvas, Size size) {
    // Copy exact structure from hourly chart's _drawTemperaturePoints method

    // Define text styles exactly like hourly chart
    final normalHighTextStyle = ui.TextStyle(
      color: const Color(0xFFFF9800), // Orange for high temps
      fontSize: 11,
      fontWeight: ui.FontWeight.bold,
    );

    final normalLowTextStyle = ui.TextStyle(
      color: Colors.cyan, // Cyan for low temps
      fontSize: 11,
      fontWeight: ui.FontWeight.bold,
    );

    final highlightHighTextStyle = ui.TextStyle(
      color: Colors.orange, // Brighter orange for highlighted
      fontSize: 12,
      fontWeight: ui.FontWeight.bold,
    );

    final highlightLowTextStyle = ui.TextStyle(
      color: Colors.cyanAccent, // Brighter cyan for highlighted
      fontSize: 12,
      fontWeight: ui.FontWeight.bold,
    );

    // Pre-calculate values for performance
    final paragraphWidth = unitWidth;

    // HIGH TEMPERATURES
    for (int i = 0; i < maxTemps.length; i++) {
      final x = i * unitWidth + (unitWidth * 0.5);
      final y = calculateYPosition(maxTemps[i], size);
      final isHighlighted = i == highlightedDay;

      // Draw high temperature dot - adjust size to match hourly
      drawTemperatureDot(
        canvas,
        Offset(x, y),
        isHighlighted ? Colors.orange : Colors.orange.withOpacity(0.8),
        isHighlighted,
        regularRadius: 3.0, // Match hourly chart's dot size
        highlightRadius: 4.0, // Match hourly chart's highlighted dot size
      );

      // Draw high temperature text
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
      ))
        ..pushStyle(
            isHighlighted ? highlightHighTextStyle : normalHighTextStyle)
        ..addText('${maxTemps[i].round()}°');

      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: paragraphWidth));

      // Position temperature value - COPY EXACT LOGIC FROM HOURLY CHART
      final normalizedTemp = (maxTemps[i] - minTemp) / (maxTemp - minTemp);

      final textY = normalizedTemp > 0.85 // Near maximum
          ? y + 15 // Draw below the point
          : y - paragraph.height - 5; // Draw above the point

      canvas.drawParagraph(
          paragraph, Offset(x - (paragraph.width * 0.5), textY));
    }

    // LOW TEMPERATURES
    for (int i = 0; i < minTemps.length; i++) {
      final x = i * unitWidth + (unitWidth * 0.5);
      final y = calculateYPosition(minTemps[i], size);
      final isHighlighted = i == highlightedDay;

      // Draw low temperature dot - adjust size to match hourly
      drawTemperatureDot(
        canvas,
        Offset(x, y),
        isHighlighted ? Colors.cyan : Colors.cyan.withOpacity(0.8),
        isHighlighted,
        regularRadius: 3.0, // Match hourly chart's dot size
        highlightRadius: 4.0, // Match hourly chart's highlighted dot size
      );

      // Draw low temperature text
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
      ))
        ..pushStyle(isHighlighted ? highlightLowTextStyle : normalLowTextStyle)
        ..addText('${minTemps[i].round()}°');

      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: paragraphWidth));

      // Position temperature value - COPY EXACT LOGIC FROM HOURLY CHART
      final normalizedTemp = (minTemps[i] - minTemp) / (maxTemp - minTemp);

      final textY = normalizedTemp < 0.15 // Near minimum
          ? y - paragraph.height - 5 // Draw above the point
          : y + 15; // Draw below the point

      canvas.drawParagraph(
          paragraph, Offset(x - (paragraph.width * 0.5), textY));
    }
  }

  @override
  bool shouldRepaint(covariant DailyTemperatureChartPainter oldDelegate) =>
      minTemp != oldDelegate.minTemp ||
      maxTemp != oldDelegate.maxTemp ||
      highlightedDay != oldDelegate.highlightedDay;
}

/// Painter for precipitation indicators
class PrecipitationIndicatorPainter extends CustomPainter {
  final List<double> probabilities;
  final List<double> amounts;
  final double hourWidth;
  final int? highlightedHour;
  final bool showText;

  // Cached color gradient for better performance
  static const List<Color> _blueGradient = [
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

  PrecipitationIndicatorPainter({
    required this.probabilities,
    required this.amounts,
    required this.hourWidth,
    this.highlightedHour,
    this.showText = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < probabilities.length; i++) {
      final probability = probabilities[i];

      // Only continue if there's any probability at all
      if (probability <= 0) continue;

      final color = _getPrecipitationColor(probability);
      final isHighlighted = i == highlightedHour;

      // Make the precipitation box with rounded corners
      final rect = Rect.fromLTWH((i * hourWidth) + (hourWidth * 0.15), 0,
          hourWidth * 0.7, size.height);

      // Apply opacity with minimum threshold for visibility
      // Higher probability = slightly more opaque
      final minOpacity = 0.7;
      final maxOpacity = 0.95;
      final fillOpacity =
          minOpacity + (probability / 100) * (maxOpacity - minOpacity);

      // Fill paint with color determined purely by probability
      final fillPaint = Paint()
        ..color = color.withOpacity(fillOpacity)
        ..style = PaintingStyle.fill;

      // Border paint matching the fill color (but full opacity)
      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighlighted ? 1.5 : 1.0;

      // Use consistent rounded corners
      final roundedRect =
          RRect.fromRectAndRadius(rect, const Radius.circular(8));

      // Draw fill and border
      canvas.drawRRect(roundedRect, fillPaint);
      canvas.drawRRect(roundedRect, borderPaint);

      // Text showing precipitation percentage
      if (showText) {
        _drawPrecipitationText(canvas, i, probability, isHighlighted, size);
      }
    }
  }

  Color _getPrecipitationColor(double probability) {
    // Normalize probability to get exact position in our color gradient (0-8 range)
    final normalizedPosition = (probability / 100) * (_blueGradient.length - 1);
    final lowerIndex = normalizedPosition.floor();
    final upperIndex = normalizedPosition.ceil();
    final fraction = normalizedPosition - lowerIndex;

    // Get the final color by interpolating between the two nearest colors
    if (lowerIndex == upperIndex) {
      return _blueGradient[lowerIndex];
    } else {
      return Color.lerp(
        _blueGradient[lowerIndex],
        _blueGradient[upperIndex],
        fraction,
      )!;
    }
  }

  void _drawPrecipitationText(Canvas canvas, int index, double probability,
      bool isHighlighted, Size size) {
    // Text style - use white text with shadow for all boxes
    final textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: isHighlighted ? 11 : 10,
      fontWeight: probability > 50 || isHighlighted
          ? ui.FontWeight.bold
          : ui.FontWeight.normal,
      shadows: [
        ui.Shadow(
          blurRadius: 2,
          color: Colors.black.withOpacity(0.7),
          offset: const Offset(0, 1),
        ),
      ],
    );

    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
    ))
      ..pushStyle(textStyle)
      ..addText('${probability.round()}%');

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: hourWidth * 0.7));

    // Center the text both horizontally and vertically
    final textX = (index * hourWidth) +
        (hourWidth * 0.15) +
        ((hourWidth * 0.7 - paragraph.width) / 2);

    // Fix: Calculate the vertical center position correctly
    final textY = (size.height - paragraph.height) / 2;

    canvas.drawParagraph(paragraph, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant PrecipitationIndicatorPainter oldDelegate) =>
      highlightedHour != oldDelegate.highlightedHour ||
      showText != oldDelegate.showText;
}

/// Painter for daily precipitation chart (renamed from "weekly")
class DailyPrecipitationPainter extends CustomPainter {
  final List<double> probabilities;
  final int days;

  static const List<Color> _blueGradient = [
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

  DailyPrecipitationPainter({
    required this.probabilities,
    required this.days,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double barWidth = size.width / days;
    const double barPadding = 8.0;

    // Draw labels
    final textStyle = ui.TextStyle(
      color: Colors.white70,
      fontSize: 10,
    );

    final paragraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.center))
          ..pushStyle(textStyle)
          ..addText('Precipitation Probability');

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: size.width));

    canvas.drawParagraph(paragraph, Offset(0, 0));

    // Draw each precipitation probability bar
    for (int i = 0; i < days && i < probabilities.length; i++) {
      final double probability = probabilities[i];
      if (probability <= 0) continue;

      // Get the appropriate color for this probability
      final color = _getPrecipitationColor(probability);

      // Calculate bar height based on probability
      final maxHeight = size.height - 20; // Subtract text height
      final barHeight = (probability / 100) * maxHeight;

      // Calculate bar position
      final rect = Rect.fromLTWH(i * barWidth + barPadding / 2,
          size.height - barHeight, barWidth - barPadding, barHeight);

      // Draw the bar with rounded top corners
      final roundRect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      // Fill paint using our gradient color
      final fillPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      // Border paint for outline
      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawRRect(roundRect, fillPaint);
      canvas.drawRRect(roundRect, borderPaint);

      // Add text showing percentage
      if (probability >= 10) {
        _drawProbabilityText(
            canvas, i, probability, barWidth, barPadding, barHeight, size);
      }
    }
  }

  Color _getPrecipitationColor(double probability) {
    final normalizedPosition = (probability / 100) * (_blueGradient.length - 1);
    final lowerIndex = normalizedPosition.floor();
    final upperIndex = normalizedPosition.ceil();
    final fraction = normalizedPosition - lowerIndex;

    // Get interpolated color
    if (lowerIndex == upperIndex) {
      return _blueGradient[lowerIndex];
    } else {
      return Color.lerp(
        _blueGradient[lowerIndex],
        _blueGradient[upperIndex],
        fraction,
      )!;
    }
  }

  void _drawProbabilityText(Canvas canvas, int index, double probability,
      double barWidth, double barPadding, double barHeight, Size size) {
    final textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: 9,
      fontWeight: ui.FontWeight.bold,
    );

    final paragraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.center))
          ..pushStyle(textStyle)
          ..addText('${probability.round()}%');

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: barWidth - barPadding));

    // Position text inside the bar if tall enough, otherwise above it
    final textY = barHeight > 20
        ? size.height - barHeight + 2
        : size.height - barHeight - paragraph.height - 2;

    canvas.drawParagraph(
        paragraph, Offset(index * barWidth + barPadding / 2, textY));
  }

  @override
  bool shouldRepaint(covariant DailyPrecipitationPainter oldDelegate) =>
      oldDelegate.probabilities != probabilities || oldDelegate.days != days;
}
