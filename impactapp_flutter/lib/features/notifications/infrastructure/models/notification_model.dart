import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.idNotificacion,
    required super.tipo,
    required super.asunto,
    required super.estado,
    required super.leida,
    required super.creadoEn,
    super.enviadoEn,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      idNotificacion: (json['id_notificacion'] as num).toInt(),
      tipo: json['tipo']?.toString() ?? '',
      asunto: json['asunto']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      leida: json['leida'] == true,
      creadoEn: json['creado_en']?.toString() ?? '',
      enviadoEn: json['enviado_en']?.toString(),
    );
  }
}
