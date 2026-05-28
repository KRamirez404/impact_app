import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../shared/theme/app_theme.dart';
import 'icon_container.dart';

class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final RxBool value;
  final Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconContainer(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w500,
                    fontSize: 14, color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w400,
                    fontSize: 12, color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value.value,
              onChanged: onChanged,
              activeThumbColor: AppColors.switchOn,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: AppColors.switchOff,
            ),
          ),
        ],
      ),
    ));
  }
}
