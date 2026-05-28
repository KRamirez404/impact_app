import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'amount_chip.dart';
import 'payment_process_dialog.dart';

Future<void> showMoneyDonationDialog({
  required BuildContext context,
  required int campaignId,
  required Future<void> Function(Map<String, dynamic>) onDonate,
}) async {
  final amountController = TextEditingController(text: '50000');
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              width: 384,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.black.withOpacity(0.1),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 15,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Realizar Donación',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Ingresa el monto que deseas donar',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF717182)),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Monto (COP)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF3F3F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF717182),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      AmountChip(
                        label: '\$20.000',
                        onTap: () =>
                            setState(() => amountController.text = '20000'),
                      ),
                      const SizedBox(width: 8),
                      AmountChip(
                        label: '\$50.000',
                        onTap: () =>
                            setState(() => amountController.text = '50000'),
                      ),
                      const SizedBox(width: 8),
                      AmountChip(
                        label: '\$100.000',
                        onTap: () =>
                            setState(() => amountController.text = '100000'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final amount =
                            double.tryParse(
                              amountController.text
                                  .replaceAll('.', '')
                                  .trim(),
                            ) ??
                            0;
                        if (amount <= 0) {
                          Get.snackbar(
                            'Monto inválido',
                            'Ingresa un monto válido para continuar',
                            backgroundColor: const Color(0xFFD32F2F),
                            colorText: Colors.white,
                          );
                          return;
                        }
                        Navigator.of(dialogContext).pop();
                        showPaymentProcessDialog(
                          context: context,
                          campaignId: campaignId,
                          amount: amount,
                          onDonate: onDonate,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Confirmar Donación',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  amountController.dispose();
}
