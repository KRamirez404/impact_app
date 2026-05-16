import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../controllers/campaign_detail_controller.dart';

class DonatePage extends StatelessWidget {
  DonatePage({super.key});
  final _tipo = 'economica'.obs;
  final _montoCtrl = TextEditingController(text: '50000');
  final _descripcionCtrl = TextEditingController();
  final CampaignDetailController controller = Get.find<CampaignDetailController>();

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
                  DropdownMenuItem(value: 'economica', child: Text('Económica')),
                  DropdownMenuItem(value: 'alimentos', child: Text('Alimentos')),
                  DropdownMenuItem(value: 'ropa', child: Text('Ropa')),
                  DropdownMenuItem(value: 'medicamentos', child: Text('Medicamentos')),
                  DropdownMenuItem(value: 'otros', child: Text('Otros')),
                ],
                onChanged: (v) => _tipo.value = v ?? 'economica',
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(controller: _montoCtrl, label: 'Monto estimado'),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _descripcionCtrl,
              label: 'Descripción',
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Obx(
              () => CustomButton(
                text: controller.isLoading.value ? 'Enviando...' : 'Registrar donación',
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        await controller.donate({
                          'id_campania': id,
                          'tipo': _tipo.value,
                          'monto_estimado': double.tryParse(_montoCtrl.text.trim()) ?? 0,
                          'descripcion': _descripcionCtrl.text.trim(),
                        });
                        Get.back();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
