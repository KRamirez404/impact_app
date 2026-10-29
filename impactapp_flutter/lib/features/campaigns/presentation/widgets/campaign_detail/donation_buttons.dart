import 'package:flutter/material.dart';

class DonationButtons extends StatelessWidget {
  const DonationButtons({
    super.key,
    required this.onDonateMoney,
    required this.onDonatePhysical,
    required this.onBankTransfer,
  });

  final VoidCallback onDonateMoney;
  final VoidCallback onDonatePhysical;
  final VoidCallback onBankTransfer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onDonateMoney,
                icon: const Icon(Icons.volunteer_activism, size: 16),
                label: const Text('Wompi'),
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
                onPressed: onBankTransfer,
                icon: const Icon(Icons.account_balance, size: 16),
                label: const Text('Transferencia'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onDonatePhysical,
            icon: const Icon(Icons.handshake_outlined, size: 16),
            label: const Text('Donación física'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0A0A0A),
              side: BorderSide(
                color: Colors.black.withValues(alpha: 0.1),
                width: 0.8,
              ),
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
