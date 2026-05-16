import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ImpactApp', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _emailCtrl,
                    label: 'Correo',
                    validator: Validators.email,
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
                      text: controller.isLoading.value ? 'Ingresando...' : 'Iniciar sesión',
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                controller.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.register),
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

