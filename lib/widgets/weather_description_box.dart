import 'package:flutter/material.dart';

/// Reusable widget for displaying weather descriptions in consistent boxes
class WeatherDescriptionBox extends StatelessWidget {
  final String description;
  final bool isHighlighted;

  const WeatherDescriptionBox({
    super.key,
    required this.description,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.blue.withOpacity(0.15)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted
              ? Colors.blue.withOpacity(0.5)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        description,
        style: TextStyle(
          fontSize: 9.0,
          color: isHighlighted ? Colors.blue.shade200 : Colors.grey.shade400,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
