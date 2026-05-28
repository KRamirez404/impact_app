import 'package:flutter/material.dart';

class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.isDisabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: isDisabled ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: labelColor ?? const Color(0xFF0A0A0A),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.1),
            width: 0.8,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor ?? const Color(0xFF0A0A0A)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Segoe UI Emoji',
                fontWeight: FontWeight.w500,
                color: labelColor ?? const Color(0xFF0A0A0A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
