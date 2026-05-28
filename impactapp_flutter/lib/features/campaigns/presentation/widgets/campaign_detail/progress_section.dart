import 'package:flutter/material.dart';

String _formatCurrencyDetailed(double amount) {
  final formatted = amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
  return '\$ $formatted';
}

class ProgressSection extends StatelessWidget {
  const ProgressSection({
    super.key,
    required this.collected,
    required this.goal,
    required this.percentage,
    required this.daysRemaining,
  });

  final double collected;
  final double goal;
  final double percentage;
  final int daysRemaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrencyDetailed(collected),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'de ${_formatCurrencyDetailed(goal)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF717182),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ((percentage / 100).clamp(0.0, 1.0)).toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}% alcanzado',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF717182),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$daysRemaining días restantes',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF717182),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
