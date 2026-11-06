import 'package:get/get.dart';

import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';

class NotificationController extends GetxController {
  final GetNotificationsUseCase getNotifications;
  final MarkNotificationReadUseCase markNotificationRead;
  final MarkAllNotificationsReadUseCase markAllNotificationsRead;

  NotificationController({
    required this.getNotifications,
    required this.markNotificationRead,
    required this.markAllNotificationsRead,
  });

  final notifications = <NotificationEntity>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final noLeidas = 0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = '';
      final items = await getNotifications();
      notifications.assignAll(items);
      _recalcularNoLeidas();
    } catch (e) {
      error.value = friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markRead(NotificationEntity notificacion) async {
    if (notificacion.leida) return;
    try {
      final actualizada = await markNotificationRead(
        notificacion.idNotificacion,
      );
      final indice = notifications.indexWhere(
        (item) => item.idNotificacion == notificacion.idNotificacion,
      );
      if (indice >= 0) {
        notifications[indice] = actualizada;
      }
      _recalcularNoLeidas();
    } catch (e) {
      Get.snackbar('No se pudo actualizar', friendlyError(e));
    }
  }

  Future<void> markAllRead() async {
    try {
      await markAllNotificationsRead();
      await load();
    } catch (e) {
      Get.snackbar('No se pudo actualizar', friendlyError(e));
    }
  }

  void _recalcularNoLeidas() {
    noLeidas.value = notifications.where((item) => !item.leida).length;
  }
}
