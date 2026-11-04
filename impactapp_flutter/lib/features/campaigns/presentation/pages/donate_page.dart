import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/cop_amount.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../controllers/campaign_detail_controller.dart';
import '../widgets/campaign_detail/money_donation_dialog.dart';

class DonatePage extends StatelessWidget {
  DonatePage({super.key});
  final _tipo = 'economica'.obs;
  final _montoCtrl = TextEditingController(text: '50000');
  final _descripcionCtrl = TextEditingController();
  final CampaignDetailController controller =
      Get.find<CampaignDetailController>();

  Future<void> _showMoneyDonation(BuildContext context, int campaignId) async {
    final status = await showMoneyDonationDialog(
      context: context,
      campaignId: campaignId,
      onCheckout: (amountCents, idempotencyKey) =>
          controller.startMoneyDonation(
            campaignId,
            amountCents,
            idempotencyKey: idempotencyKey,
          ),
      onCheckStatus: (donationId) => controller.checkDonationStatus(donationId),
    );
    if (status == 'aprobada') {
      await controller.loadCampaign(campaignId);
    }
  }

  Future<void> _registrarDonacionFisica(
    BuildContext context,
    int campaignId,
  ) async {
    final parsed = parseCopAmount(_montoCtrl.text);
    if (!parsed.isValid) {
      Get.snackbar(
        'Monto inválido',
        parsed.error ?? 'Ingresa un monto válido',
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
      return;
    }
    await controller.donate({
      'id_campania': campaignId,
      'tipo': _tipo.value,
      'monto_estimado': parsed.cents! / 100,
      'descripcion': _descripcionCtrl.text.trim(),
    });
    if (context.mounted) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = int.parse(Get.parameters['id'] ?? '0');
    return Scaffold(
      appBar: AppBar(title: const Text('Donar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: _tipo.value,
                items: const [
                  DropdownMenuItem(
                    value: 'economica',
                    child: Text('Económica'),
                  ),
                  DropdownMenuItem(
                    value: 'alimentos',
                    child: Text('Alimentos'),
                  ),
                  DropdownMenuItem(value: 'ropa', child: Text('Ropa')),
                  DropdownMenuItem(
                    value: 'medicamentos',
                    child: Text('Medicamentos'),
                  ),
                  DropdownMenuItem(value: 'otros', child: Text('Otros')),
                ],
                onChanged: (v) => _tipo.value = v ?? 'economica',
              ),
            ),
            Obx(
              () => _tipo.value == 'economica'
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: const Text(
                          'El pago económico se realiza en Wompi Sandbox. '
                          'El monto se confirma en el siguiente paso.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _montoCtrl,
                          label: 'Monto estimado',
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _descripcionCtrl,
                          label: 'Descripción',
                          maxLines: 3,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => CustomButton(
                text: controller.isLoading.value
                    ? 'Enviando...'
                    : _tipo.value == 'economica'
                    ? 'Continuar con Wompi'
                    : 'Registrar donación',
                onPressed: controller.isLoading.value
                    ? null
                    : () {
                        if (_tipo.value == 'economica') {
                          _showMoneyDonation(context, id);
                        } else {
                          _registrarDonacionFisica(context, id);
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
