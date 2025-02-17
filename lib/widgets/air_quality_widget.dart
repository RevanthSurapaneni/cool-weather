import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class AirQualityUtils {
  // Each pollutant has different breakpoints based on EPA standards
  static (String, double, double) _getMainPollutant(AirQualityData data) {
    // Scale each pollutant to its own index (based on EPA standards)
    Map<String, double> scaledValues = {
      'PM2.5': data.pm2_5 / 12.0, // Good level is ≤ 12.0 μg/m³
      'PM10': data.pm10 / 54.0, // Good level is ≤ 54 μg/m³
      'NO₂': data.nitrogen_dioxide / 53, // Good level is ≤ 53 ppb
      'O₃': data.ozone / 54, // Good level is ≤ 54 ppb (8-hour)
      'SO₂': data.sulphur_dioxide / 35, // Good level is ≤ 35 ppb
    };

    // Find the worst pollutant (highest ratio compared to its "good" threshold)
    String worstPollutant = 'PM2.5'; // default
    double maxRatio = 0;
    double actualValue = 0;

    scaledValues.forEach((pollutant, ratio) {
      if (ratio > maxRatio) {
        maxRatio = ratio;
        worstPollutant = pollutant;
        switch (pollutant) {
          case 'PM2.5':
            actualValue = data.pm2_5;
            break;
          case 'PM10':
            actualValue = data.pm10;
            break;
          case 'NO₂':
            actualValue = data.nitrogen_dioxide;
            break;
          case 'O₃':
            actualValue = data.ozone;
            break;
          case 'SO₂':
            actualValue = data.sulphur_dioxide;
            break;
        }
      }
    });

    return (worstPollutant, actualValue, maxRatio);
  }

  static (String, Color, String, double) getAQIInfo(AirQualityData data) {
    final (pollutant, value, ratio) = _getMainPollutant(data);

    // Determine AQI category based on ratio
    String description;
    Color color;
    String advice;

    if (ratio <= 1.0) {
      description = 'Good';
      color = Colors.green;
      advice = 'Air quality is good, enjoy outdoor activities';
    } else if (ratio <= 2.0) {
      description = 'Moderate';
      color = Colors.yellow;
      advice =
          'Acceptable air quality. Consider reducing prolonged outdoor activity if sensitive';
    } else if (ratio <= 3.0) {
      description = 'Unhealthy for Sensitive Groups';
      color = Colors.orange;
      advice = 'Sensitive groups should limit outdoor activities';
    } else if (ratio <= 4.0) {
      description = 'Unhealthy';
      color = Colors.red;
      advice = 'Everyone should reduce outdoor activities';
    } else if (ratio <= 5.0) {
      description = 'Very Unhealthy';
      color = Colors.purple;
      advice = 'Avoid outdoor activities if possible';
    } else {
      description = 'Hazardous';
      color = Colors.brown;
      advice = 'Stay indoors, avoid all outdoor activities';
    }

    return (description, color, pollutant, value);
  }
}

class AirQualityWidget extends StatelessWidget {
  final AirQualityData data;

  const AirQualityWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final (description, color, pollutant, value) =
        AirQualityUtils.getAQIInfo(data);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.air, color: color),
                const SizedBox(width: 8),
                Text(
                  'Air Quality',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      'Main pollutant: $pollutant (${value.toStringAsFixed(1)} μg/m³)',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.circle,
                  size: 48,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildPollutantChip(
                    'PM2.5', '${data.pm2_5.toStringAsFixed(1)} μg/m³'),
                _buildPollutantChip(
                    'PM10', '${data.pm10.toStringAsFixed(1)} μg/m³'),
                _buildPollutantChip(
                    'NO₂', '${data.nitrogen_dioxide.toStringAsFixed(1)} μg/m³'),
                _buildPollutantChip(
                    'O₃', '${data.ozone.toStringAsFixed(1)} μg/m³'),
                _buildPollutantChip(
                    'SO₂', '${data.sulphur_dioxide.toStringAsFixed(1)} μg/m³'),
                // Convert CO from μg/m³ to mg/m³ (divide by 1000)
                _buildPollutantChip('CO',
                    '${(data.carbon_monoxide / 1000).toStringAsFixed(2)} mg/m³'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollutantChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
