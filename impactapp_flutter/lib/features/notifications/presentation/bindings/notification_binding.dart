import 'package:get/get.dart';

import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../infrastructure/datasources/notification_remote_datasource.dart';
import '../../infrastructure/repositories/notification_repository_impl.dart';
import '../controllers/notification_controller.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSource(),
    );
    Get.lazyPut<NotificationRepository>(
      () => NotificationRepositoryImpl(Get.find<NotificationRemoteDataSource>()),
    );
    Get.lazyPut<GetNotificationsUseCase>(
      () => GetNotificationsUseCase(Get.find<NotificationRepository>()),
    );
    Get.lazyPut<MarkNotificationReadUseCase>(
      () => MarkNotificationReadUseCase(Get.find<NotificationRepository>()),
    );
    Get.lazyPut<MarkAllNotificationsReadUseCase>(
      () => MarkAllNotificationsReadUseCase(Get.find<NotificationRepository>()),
    );
    Get.lazyPut<NotificationController>(
      () => NotificationController(
        getNotifications: Get.find<GetNotificationsUseCase>(),
        markNotificationRead: Get.find<MarkNotificationReadUseCase>(),
        markAllNotificationsRead: Get.find<MarkAllNotificationsReadUseCase>(),
      ),
      fenix: true,
    );
  }
}
