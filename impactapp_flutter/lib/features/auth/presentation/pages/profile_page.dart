import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../controllers/auth_controller.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});
  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Obx(
        () {
          final user = controller.user.value;
          if (user == null) return const Center(child: Text('Sin datos de usuario'));
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.nombre} ${user.apellido}', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Correo: ${user.correo}'),
                Text('Teléfono: ${user.telefono ?? '-'}'),
                Text('Estado: ${user.estado}'),
                const SizedBox(height: 24),
                CustomButton(text: 'Cerrar sesión', onPressed: controller.logout),
              ],
            ),
          );
        },
      ),
    );
  }
}

