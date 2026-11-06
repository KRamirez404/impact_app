import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications();
  Future<NotificationEntity> markRead(int idNotificacion);
  Future<int> markAllRead();
}
