import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationRepository repository;
  MarkNotificationReadUseCase(this.repository);

  Future<NotificationEntity> call(int idNotificacion) =>
      repository.markRead(idNotificacion);
}
