import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4)),
            BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 22, color: valueColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF717182))),
          ],
        ),
      ),
    );
  }
}
