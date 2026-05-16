import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../controllers/collection_point_controller.dart';

class CreateCollectionPointPage extends StatelessWidget {
  CreateCollectionPointPage({super.key});
  final _ciudadCtrl = TextEditingController(text: '1');
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _horarioCtrl = TextEditingController();
  final _contactoCtrl = TextEditingController();
  final CollectionPointController controller = Get.find<CollectionPointController>();

  @override
  Widget build(BuildContext context) {
    final id = int.parse(Get.parameters['id'] ?? '0');
    return Scaffold(
      appBar: AppBar(title: const Text('Crear punto de recolección')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            CustomTextField(controller: _ciudadCtrl, label: 'ID Ciudad'),
            const SizedBox(height: 12),
            CustomTextField(controller: _nombreCtrl, label: 'Nombre'),
            const SizedBox(height: 12),
            CustomTextField(controller: _direccionCtrl, label: 'Dirección'),
            const SizedBox(height: 12),
            CustomTextField(controller: _horarioCtrl, label: 'Horario'),
            const SizedBox(height: 12),
            CustomTextField(controller: _contactoCtrl, label: 'Contacto'),
            const SizedBox(height: 20),
            Obx(
              () => CustomButton(
                text: controller.isLoading.value ? 'Guardando...' : 'Guardar punto',
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.create({
                          'id_campania': id,
                          'id_ciudad': int.parse(_ciudadCtrl.text.trim()),
                          'nombre': _nombreCtrl.text.trim(),
                          'direccion': _direccionCtrl.text.trim(),
                          'horario': _horarioCtrl.text.trim(),
                          'contacto': _contactoCtrl.text.trim(),
                        }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

