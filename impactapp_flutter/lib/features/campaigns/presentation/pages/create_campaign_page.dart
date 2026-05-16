import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../controllers/campaign_list_controller.dart';

class CreateCampaignPage extends StatelessWidget {
  CreateCampaignPage({super.key});
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController(text: '1');
  final _categoriaCtrl = TextEditingController(text: '1');
  final _metaCtrl = TextEditingController(text: '1000000');
  final _fechaFinCtrl = TextEditingController(text: '2026-12-31');
  final _tipoAyuda = 'economica'.obs;
  final CampaignListController controller = Get.find<CampaignListController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear campaña')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              CustomTextField(
                controller: _tituloCtrl,
                label: 'Título',
                validator: (v) => Validators.requiredField(v, 'Título'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _descripcionCtrl,
                label: 'Descripción',
                maxLines: 4,
                validator: (v) => Validators.requiredField(v, 'Descripción'),
              ),
              const SizedBox(height: 12),
              CustomTextField(controller: _ciudadCtrl, label: 'ID Ciudad'),
              const SizedBox(height: 12),
              CustomTextField(controller: _categoriaCtrl, label: 'ID Categoría'),
              const SizedBox(height: 12),
              CustomTextField(controller: _metaCtrl, label: 'Meta monetaria'),
              const SizedBox(height: 12),
              CustomTextField(controller: _fechaFinCtrl, label: 'Fecha fin (YYYY-MM-DD)'),
              const SizedBox(height: 12),
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: _tipoAyuda.value,
                  items: const [
                    DropdownMenuItem(value: 'economica', child: Text('Económica')),
                    DropdownMenuItem(value: 'alimentos', child: Text('Alimentos')),
                    DropdownMenuItem(value: 'ropa', child: Text('Ropa')),
                    DropdownMenuItem(value: 'medicamentos', child: Text('Medicamentos')),
                    DropdownMenuItem(value: 'mixta', child: Text('Mixta')),
                  ],
                  onChanged: (v) => _tipoAyuda.value = v ?? 'economica',
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => CustomButton(
                  text: controller.isLoading.value ? 'Guardando...' : 'Crear',
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            controller.createCampaign({
                              'titulo': _tituloCtrl.text.trim(),
                              'descripcion': _descripcionCtrl.text.trim(),
                              'id_ciudad': int.parse(_ciudadCtrl.text.trim()),
                              'id_categoria': int.parse(_categoriaCtrl.text.trim()),
                              'tipo_ayuda_requerida': _tipoAyuda.value,
                              'meta_monetaria': double.parse(_metaCtrl.text.trim()),
                              'fecha_fin': _fechaFinCtrl.text.trim(),
                            });
                          }
                        },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
