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
  final _obscurePass = true.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 412),
              child: Column(
                children: [
                  const SizedBox(height: 45),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/logo/logo.png',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'ImpactApp',
          style: TextStyle(
            fontFamily: 'Audiowide',
            fontSize: 30,
            color: Color(0xFF1976D2),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Donaciones con propósito',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF717182),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      width: 378.4,
      padding: const EdgeInsets.fromLTRB(24.8, 24.8, 24.8, 0.8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF0A0A0A),
              ),
            ),
            const SizedBox(height: 24),
            _buildForm(),
            const SizedBox(height: 24),
            _buildRegisterLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _emailCtrl,
          label: 'Correo electrónico',
          validator: Validators.email,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        Obx(
          () => CustomTextField(
            controller: _passCtrl,
            label: 'Contraseña',
            obscure: _obscurePass.value,
            validator: Validators.password,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass.value ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF717182),
                size: 20,
              ),
              onPressed: () => _obscurePass.toggle(),
              splashRadius: 1,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Obx(
          () => CustomButton(
            text: controller.isLoading.value ? 'Ingresando...' : 'Iniciar Sesión',
            onPressed: controller.isLoading.value
                ? null
                : _submit,
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      controller.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    }
  }

  Widget _buildRegisterLink() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.register),
        child: const Text(
          '¿No tienes cuenta? Regístrate aquí',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF717182),
          ),
        ),
      ),
    );
  }
}
