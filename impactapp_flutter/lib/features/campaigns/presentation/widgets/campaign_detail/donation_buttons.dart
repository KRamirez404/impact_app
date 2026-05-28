import 'package:flutter/material.dart';

class DonationButtons extends StatelessWidget {
  const DonationButtons({
    super.key,
    required this.onDonateMoney,
    required this.onDonatePhysical,
  });

  final VoidCallback onDonateMoney;
  final VoidCallback onDonatePhysical;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onDonateMoney,
            icon: const Icon(Icons.volunteer_activism, size: 16),
            label: const Text('Donar dinero'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDonatePhysical,
            icon: const Icon(Icons.handshake_outlined, size: 16),
            label: const Text('Donar físico'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0A0A0A),
              side: BorderSide(
                color: Colors.black.withOpacity(0.1),
                width: 0.8,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
