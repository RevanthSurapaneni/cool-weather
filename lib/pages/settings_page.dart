import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final bool useMetric;
  final Function(bool) onUnitChanged;

  const SettingsPage({
    super.key,
    required this.useMetric,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Use Metric Units'),
            subtitle: const Text('Celsius, kilometers per hour'),
            trailing: Switch(
              value: useMetric,
              onChanged: onUnitChanged,
            ),
          ),
        ],
      ),
    );
  }
}
