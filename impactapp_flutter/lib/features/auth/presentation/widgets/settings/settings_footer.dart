import 'package:flutter/material.dart';

class SettingsFooter extends StatelessWidget {
  const SettingsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Text(
            'ImpactApp © 2026',
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 12, color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Donaciones con transparencia y confianza',
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 12, color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
