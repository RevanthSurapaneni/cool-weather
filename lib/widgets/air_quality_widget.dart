import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class AirQualityUtils {
  static (String, Color, String, String, List<String>) getAQIInfo(
      AirQualityData data) {
    // Using US AQI standards
    final int aqi = data.usAQI;
    String category;
    Color color;
    String description;
    String mainAdvice;
    List<String> sensitiveGroups;

    if (aqi <= 50) {
      category = 'Good';
      color = Colors.green;
      description = 'Air quality is satisfactory';
      mainAdvice = 'Perfect for outdoor activities';
      sensitiveGroups = ['None'];
    } else if (aqi <= 100) {
      category = 'Moderate';
      color = Colors.yellow;
      description = 'Air quality is acceptable';
      mainAdvice =
          'Unusually sensitive people should consider reducing prolonged outdoor exertion';
      sensitiveGroups = ['People with respiratory diseases'];
    } else if (aqi <= 150) {
      category = 'Unhealthy for Sensitive Groups';
      color = Colors.orange;
      description = 'Members of sensitive groups may experience health effects';
      mainAdvice = 'Reduce prolonged or heavy outdoor exertion';
      sensitiveGroups = [
        'People with lung disease',
        'Children and older adults',
        'People who are active outdoors'
      ];
    } else if (aqi <= 200) {
      category = 'Unhealthy';
      color = Colors.red;
      description = 'Everyone may begin to experience health effects';
      mainAdvice = 'Avoid prolonged outdoor exertion';
      sensitiveGroups = [
        'People with respiratory or heart disease',
        'Children and older adults',
        'Everyone who is active outdoors'
      ];
    } else if (aqi <= 300) {
      category = 'Very Unhealthy';
      color = Colors.purple;
      description = 'Health warnings of emergency conditions';
      mainAdvice = 'Avoid all outdoor activities';
      sensitiveGroups = ['Everyone'];
    } else {
      category = 'Hazardous';
      color = Colors.brown;
      description =
          'Health alert: everyone may experience serious health effects';
      mainAdvice = 'Stay indoors and keep activity levels low';
      sensitiveGroups = ['Everyone'];
    }

    return (category, color, description, mainAdvice, sensitiveGroups);
  }
}

class AirQualityWidget extends StatelessWidget {
  final AirQualityData data;

  const AirQualityWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final (category, color, description, mainAdvice, sensitiveGroups) =
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
                      category,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      'AQI: ${data.usAQI}',
                      style: TextStyle(
                        fontSize: 16,
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
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              mainAdvice,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (sensitiveGroups.isNotEmpty &&
                sensitiveGroups.first != 'None') ...[
              const SizedBox(height: 16),
              Text(
                'Sensitive Groups:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...sensitiveGroups.map((group) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right, size: 16),
                        Text(group),
                      ],
                    ),
                  )),
            ],
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
