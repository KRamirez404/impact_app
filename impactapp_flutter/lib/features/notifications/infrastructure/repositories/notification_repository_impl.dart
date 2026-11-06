import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource dataSource;
  const NotificationRepositoryImpl(this.dataSource);

  @override
  Future<List<NotificationEntity>> getNotifications() =>
      dataSource.getNotifications();

  @override
  Future<NotificationEntity> markRead(int idNotificacion) =>
      dataSource.markRead(idNotificacion);

  @override
  Future<int> markAllRead() => dataSource.markAllRead();
}
