import 'package:flutter/material.dart';
import '../../../../../shared/theme/app_theme.dart';

class SettingsFooter extends StatelessWidget {
  const SettingsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Text(
            'ImpactApp © 2026',
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 12, color: AppColors.footerText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Donaciones con transparencia y confianza',
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 12, color: AppColors.footerSubtitle,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
