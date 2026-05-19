import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1976D2);
  static const surface = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF0A0A0A);
  static const textSecondary = Color(0xFF717182);
  static const inputBg = Color(0xFFF3F3F5);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Segoe UI Emoji',
  );
}
