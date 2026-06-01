import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../controllers/support_controller.dart';

class SupportCampaignDetailPage extends GetView<SupportController> {
  SupportCampaignDetailPage({super.key});

  int get _id => int.parse(Get.parameters['id'] ?? '0');

  final _rejectController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    controller.loadCampaignDetail(_id);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle campaña')),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        final c = controller.campaignDetail.value;
        if (c == null) return const Center(child: Text('No se encontró la campaña'));
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(c.descripcion),
              const SizedBox(height: 12),
              if (c.notaRevision != null && c.notaRevision!.isNotEmpty) ...[
                const Text('Nota de revisión:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(c.notaRevision!),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await controller.approve(_id);
                      Get.offAllNamed(AppRoutes.supportHome);
                    },
                    child: const Text('Aprobar'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      Get.dialog(AlertDialog(
                        title: const Text('Rechazar campaña'),
                        content: TextField(
                          controller: _rejectController,
                          maxLines: 4,
                          decoration: const InputDecoration(hintText: 'Escribe la razón del rechazo'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final note = _rejectController.text.trim();
                              if (note.isEmpty) {
                                Get.snackbar('Error', 'La nota es requerida');
                                return;
                              }
                              await controller.reject(_id, note);
                              Get.offAllNamed(AppRoutes.supportHome);
                            },
                            child: const Text('Rechazar'),
                          ),
                        ],
                      ));
                    },
                    child: const Text('Rechazar'),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
