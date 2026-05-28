import 'package:flutter/material.dart';
import '../../../../../shared/theme/app_theme.dart';

class IconContainer extends StatelessWidget {
  const IconContainer({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.iconGradientStart, AppColors.iconGradientEnd],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: AppColors.gradientStart, size: 20),
    );
  }
}
