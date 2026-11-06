import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final Dio _dio;

  NotificationRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  Map<String, dynamic> _map(dynamic data) {
    if (data is! Map) throw ServerException('Respuesta inválida del servidor');
    return Map<String, dynamic>.from(data);
  }

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _dio.get(ApiConstants.notifications);
    final data = _map(response.data);
    final items = data['items'];
    if (items is! List) {
      throw ServerException('Respuesta inválida del servidor');
    }
    return items.map((item) => NotificationModel.fromJson(_map(item))).toList();
  }

  Future<NotificationModel> markRead(int idNotificacion) async {
    final response = await _dio.post(ApiConstants.notificationRead(idNotificacion));
    return NotificationModel.fromJson(_map(response.data));
  }

  Future<int> markAllRead() async {
    final response = await _dio.post(ApiConstants.notificationsReadAll);
    final data = _map(response.data);
    final marcadas = data['marcadas'];
    return marcadas is num ? marcadas.toInt() : 0;
  }
}
