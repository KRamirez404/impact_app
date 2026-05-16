import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  CustomTextField(
                    controller: _nombreCtrl,
                    label: 'Nombre',
                    validator: (v) => Validators.requiredField(v, 'Nombre'),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _apellidoCtrl,
                    label: 'Apellido',
                    validator: (v) => Validators.requiredField(v, 'Apellido'),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _correoCtrl,
                    label: 'Correo',
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _telefonoCtrl,
                    label: 'Teléfono',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _passCtrl,
                    label: 'Contraseña',
                    obscure: true,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => CustomButton(
                      text: controller.isLoading.value ? 'Registrando...' : 'Crear cuenta',
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                controller.register(
                                  nombre: _nombreCtrl.text.trim(),
                                  apellido: _apellidoCtrl.text.trim(),
                                  correo: _correoCtrl.text.trim(),
                                  contrasena: _passCtrl.text.trim(),
                                  telefono: _telefonoCtrl.text.trim(),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

