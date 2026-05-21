import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1976D2);
  static const surface = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF0A0A0A);
  static const textSecondary = Color(0xFF717182);
  static const inputBg = Color(0xFFF3F3F5);

  static const gradientStart = Color(0xFF155DFC);
  static const gradientEnd = Color(0xFF00A63E);
  static const settingsBackground = Color(0xFFF9FAFB);
  static const cardBorder = Color(0x1A000000);
  static const iconGradientStart = Color(0xFFDBEAFE);
  static const iconGradientEnd = Color(0xFFDCFCE7);
  static const sectionHeader = Color(0xFF6A7282);
  static const subtitle = Color(0xFF4A5565);
  static const switchOn = Color(0xFF1976D2);
  static const switchOff = Color(0xFFCBCED4);
  static const chevronColor = Color(0xFF99A1AF);
  static const dangerText = Color(0xFFE7000B);
  static const dangerSubtitle = Color(0xFFFB2C36);
  static const dangerIconBg = Color(0xFFFFE2E2);
  static const footerText = Color(0xFF6A7282);
  static const footerSubtitle = Color(0xFF99A1AF);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Segoe UI Emoji',
  );
}
