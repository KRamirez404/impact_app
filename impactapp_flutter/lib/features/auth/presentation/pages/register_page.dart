import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
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
  final _obscurePass = true.obs;
  final _rol = 'donante'.obs;
  final _aceptaTratamiento = false.obs;

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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 412),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 45),
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
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
          'Crear tu cuenta',
          style: TextStyle(fontSize: 16, color: Color(0xFF717182)),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
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
              'Registro',
              style: TextStyle(fontSize: 20, color: Color(0xFF0A0A0A)),
            ),
            const SizedBox(height: 24),
            _buildForm(),
            const SizedBox(height: 24),
            _buildLoginLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _nombreCtrl,
          label: 'Nombre',
          validator: (v) => Validators.requiredField(v, 'Nombre'),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _apellidoCtrl,
          label: 'Apellido',
          validator: (v) => Validators.requiredField(v, 'Apellido'),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _correoCtrl,
          label: 'Correo electrónico',
          validator: Validators.email,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _telefonoCtrl,
          label: 'Teléfono',
        ),
        const SizedBox(height: 16),
        Obx(
          () => CustomTextField(
            controller: _passCtrl,
            label: 'Contraseña',
            obscure: _obscurePass.value,
            validator: Validators.password,
            textInputAction: TextInputAction.done,
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
        _buildRoleSelector(),
        const SizedBox(height: 16),
        Obx(
          () => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _aceptaTratamiento.toggle(),
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: _aceptaTratamiento.value ? const Color(0xFF1976D2) : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _aceptaTratamiento.value
                          ? const Color(0xFF1976D2)
                          : const Color(0xFFD9D9E0),
                      width: 1.4,
                    ),
                  ),
                  child: _aceptaTratamiento.value
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF717182), height: 1.4),
                    children: [
                      const TextSpan(
                        text: 'He leído y acepto la ',
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                          child: const Text(
                            'Política de Tratamiento de Datos Personales',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' (Ley 1581 de 2012).'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Obx(
          () => CustomButton(
            text: controller.isLoading.value ? 'Registrando...' : 'Crear cuenta',
            onPressed: controller.isLoading.value
                ? null
                : () {
                    if (!_aceptaTratamiento.value) {
                      Get.snackbar(
                        'Aviso de privacidad',
                        'Debes aceptar la política de tratamiento de datos personales.',
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                      );
                      return;
                    }
                    if (_formKey.currentState!.validate()) {
                      controller.register(
                        nombre: _nombreCtrl.text.trim(),
                        apellido: _apellidoCtrl.text.trim(),
                        correo: _correoCtrl.text.trim(),
                        contrasena: _passCtrl.text.trim(),
                        telefono: _telefonoCtrl.text.trim(),
                        rol: _rol.value,
                        aceptaTratamiento: true,
                      );
                    }
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quiero registrarme como',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF0A0A0A),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _roleCard(
                  label: 'Donante',
                  subtitle: 'Apoyar campañas',
                  icon: Icons.favorite_outline,
                  selected: _rol.value == 'donante',
                  onTap: () => _rol.value = 'donante',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _roleCard(
                  label: 'Organizador',
                  subtitle: 'Crear campañas',
                  icon: Icons.campaign_outlined,
                  selected: _rol.value == 'organizador',
                  onTap: () => _rol.value = 'organizador',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roleCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE3F0FB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1976D2) : const Color(0xFFD9D9E0),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? const Color(0xFF1976D2) : const Color(0xFF717182),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFF1976D2) : const Color(0xFF0A0A0A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF717182)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Get.offNamed(AppRoutes.login),
        child: const Text(
          '¿Ya tienes cuenta? Inicia sesión',
          style: TextStyle(fontSize: 14, color: Color(0xFF717182)),
        ),
      ),
    );
  }
}
