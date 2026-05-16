import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../controllers/verification_controller.dart';

class UploadSupportPage extends StatelessWidget {
  UploadSupportPage({super.key});
  final VerificationController controller = Get.find<VerificationController>();
  final _descripcionCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final id = int.parse(Get.parameters['id'] ?? '0');
    return Scaffold(
      appBar: AppBar(title: const Text('Subir soporte')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.selectedType.value,
                items: const [
                  DropdownMenuItem(value: 'documento_oficial', child: Text('Documento oficial')),
                  DropdownMenuItem(value: 'imagen', child: Text('Imagen')),
                  DropdownMenuItem(value: 'enlace_medio', child: Text('Enlace medio')),
                  DropdownMenuItem(value: 'certificado_institucional', child: Text('Certificado')),
                ],
                onChanged: (v) => controller.selectedType.value = v ?? 'imagen',
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(controller: _descripcionCtrl, label: 'Descripción'),
            const SizedBox(height: 12),
            CustomTextField(controller: _urlCtrl, label: 'URL (si aplica)'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await _picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  controller.filePath.value = picked.path;
                }
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Seleccionar archivo'),
            ),
            const SizedBox(height: 16),
            Obx(() => Text(controller.filePath.value.isEmpty ? 'Sin archivo seleccionado' : controller.filePath.value)),
            const SizedBox(height: 20),
            Obx(
              () => CustomButton(
                text: controller.isLoading.value ? 'Enviando...' : 'Subir soporte',
                onPressed: controller.isLoading.value
                    ? null
                    : () {
                        controller.link.value = _urlCtrl.text.trim();
                        controller.submit(
                          idCampania: id,
                          descripcion: _descripcionCtrl.text.trim(),
                        );
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
