import 'package:flutter/material.dart';
import '../utils/ui_constants.dart';

/// Reusable widget for showing precipitation probability
class PrecipitationIndicator extends StatelessWidget {
  final double probability;
  final bool isHighlighted;
  final double height;
  final double width;

  const PrecipitationIndicator({
    super.key,
    required this.probability,
    required this.width,
    this.height = 20,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    // Skip if no probability
    if (probability <= 0) return SizedBox(width: width, height: height);

    // Get color from our utility
    final color = WeatherUIConstants.getPrecipitationColor(
        probability, 0.7 + (probability / 100) * 0.25);

    return Center(
      child: Container(
        width: width * 0.7, // Use 70% of allocated width
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: WeatherUIConstants.getPrecipitationColor(probability, 1.0),
            width: isHighlighted ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            '${probability.round()}%',
            style: TextStyle(
              color: Colors.white,
              fontSize: isHighlighted ? 11 : 10,
              fontWeight: probability > 50 || isHighlighted
                  ? FontWeight.bold
                  : FontWeight.normal,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.7),
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
