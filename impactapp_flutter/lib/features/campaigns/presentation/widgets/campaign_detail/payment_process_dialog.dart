import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/donation_checkout_entity.dart';
import 'payment_status_dialog.dart';

String _formatCurrency(double amount) {
  if (amount >= 1000000) {
    final millones = (amount / 1000000).toStringAsFixed(1);
    return '\$${millones.replaceAll('.', ',')}M';
  }
  if (amount >= 1000) {
    final miles = (amount / 1000).toStringAsFixed(0);
    return '\$$miles.000';
  }
  return '\$${amount.toStringAsFixed(0)}';
}

Future<String?> showPaymentProcessDialog({
  required BuildContext context,
  required double amount,
  required Future<DonationCheckoutEntity?> Function(double amount) onCheckout,
  required Future<String> Function(int donationId) onCheckStatus,
}) async {
  var acceptTerms = false;
  var isSaving = false;
  String? checkoutUrl;
  int? donationId;

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
              width: 382,
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.credit_card,
                          color: Color(0xFF1976D2),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Realizar Donación',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x0D1976D2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x331976D2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monto a donar',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF717182),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatCurrency(amount),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Método de pago',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x0D1976D2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1976D2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0x1A1976D2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.account_balance,
                              color: Color(0xFF1976D2),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wompi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tarjetas, PSE y Nequi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF717182),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: acceptTerms,
                          onChanged: isSaving
                              ? null
                              : (value) => setState(
                                  () => acceptTerms = value ?? false,
                                ),
                          activeColor: const Color(0xFF1976D2),
                        ),
                        const Expanded(
                          child: Text(
                            'Acepto los términos y condiciones y autorizo el débito correspondiente.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF717182),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFB9F8CF)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: Color(0xFF00A63E),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'El pago se procesa de forma segura en Wompi. No almacenamos datos de tu tarjeta.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF016630),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: !acceptTerms || isSaving
                            ? null
                            : () async {
                                setState(() => isSaving = true);
                                final checkout = await onCheckout(amount);
                                if (checkout == null) {
                                  if (dialogContext.mounted) {
                                    setState(() => isSaving = false);
                                  }
                                  return;
                                }
                                checkoutUrl = checkout.checkoutUrl;
                                donationId = checkout.idDonacion;
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Pagar con Wompi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: isSaving
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                        child: const Text(
                          'Volver',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  if (checkoutUrl == null || donationId == null) {
    return null;
  }

  if (!context.mounted) {
    return null;
  }

  final uri = Uri.tryParse(checkoutUrl!);
  if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    Get.snackbar(
      'Error',
      'No se pudo abrir la pasarela de pago',
      backgroundColor: const Color(0xFFD32F2F),
      colorText: Colors.white,
    );
    return null;
  }

  if (!context.mounted) {
    return null;
  }

  return showPaymentStatusDialog(
    context: context,
    donationId: donationId!,
    onCheckStatus: onCheckStatus,
  );
}
