import 'package:flutter/material.dart';

class TransferStatusChip extends StatelessWidget {
  final String status;
  const TransferStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final labels = {
      'registrada': 'Registrada',
      'en_revision': 'En revisión',
      'aprobada': 'Aprobada',
      'rechazada': 'Rechazada',
    };
    final colors = {
      'registrada': const Color(0xFF1976D2),
      'en_revision': const Color(0xFFF59E0B),
      'aprobada': const Color(0xFF00A63E),
      'rechazada': const Color(0xFFD32F2F),
    };
    final color = colors[status] ?? const Color(0xFF717182);
    return Chip(
      label: Text(labels[status] ?? status),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }
}
