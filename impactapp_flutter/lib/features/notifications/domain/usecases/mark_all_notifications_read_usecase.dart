import '../repositories/notification_repository.dart';

class MarkAllNotificationsReadUseCase {
  final NotificationRepository repository;
  MarkAllNotificationsReadUseCase(this.repository);

  Future<int> call() => repository.markAllRead();
}
