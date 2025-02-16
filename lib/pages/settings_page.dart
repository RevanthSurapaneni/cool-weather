import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final bool useMetric;
  final bool useDarkMode;
  final Function(bool) onUnitChanged;
  final Function(bool) onThemeChanged;

  const SettingsPage({
    super.key,
    required this.useMetric,
    required this.useDarkMode,
    required this.onUnitChanged,
    required this.onThemeChanged,
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
          ListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle dark/light theme'),
            trailing: Switch(
              value: useDarkMode,
              onChanged: onThemeChanged,
            ),
          ),
        ],
      ),
    );
  }
}
