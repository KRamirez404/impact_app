import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/notification_entity.dart';
import '../controllers/notification_controller.dart';

class NotificationsPage extends StatelessWidget {
  NotificationsPage({super.key});

  final NotificationController controller =
      Get.find<NotificationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Marcar todas como leídas',
              onPressed: controller.noLeidas.value > 0
                  ? controller.markAllRead
                  : null,
              icon: const Icon(Icons.done_all),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty &&
            controller.notifications.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(controller.error.value, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: controller.load,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        if (controller.notifications.isEmpty) {
          return const Center(
            child: Text('No tienes notificaciones por ahora'),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            itemCount: controller.notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final notificacion = controller.notifications[index];
              return _NotificationTile(
                notificacion: notificacion,
                onTap: () => controller.markRead(notificacion),
              );
            },
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notificacion, required this.onTap});

  final NotificationEntity notificacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fecha = DateTime.tryParse(notificacion.creadoEn)?.toLocal();
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.iconGradientStart,
        child: Icon(_icono(notificacion.tipo), color: AppColors.primary),
      ),
      title: Text(
        notificacion.asunto,
        style: TextStyle(
          fontWeight: notificacion.leida ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        fecha == null
            ? ''
            : DateFormat('dd/MM/yyyy HH:mm').format(fecha),
      ),
      trailing: notificacion.leida
          ? const Icon(Icons.check, size: 18, color: AppColors.chevronColor)
          : const Icon(Icons.circle, size: 10, color: AppColors.primary),
      onTap: onTap,
    );
  }

  IconData _icono(String tipo) {
    if (tipo.startsWith('donacion_')) return Icons.volunteer_activism;
    if (tipo.startsWith('transferencia_')) return Icons.account_balance;
    if (tipo == 'campania_creada') return Icons.campaign_outlined;
    if (tipo == 'bienvenida') return Icons.celebration_outlined;
    return Icons.notifications_none;
  }
}
