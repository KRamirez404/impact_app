class NotificationEntity {
  final int idNotificacion;
  final String tipo;
  final String asunto;
  final String estado;
  final bool leida;
  final String creadoEn;
  final String? enviadoEn;

  const NotificationEntity({
    required this.idNotificacion,
    required this.tipo,
    required this.asunto,
    required this.estado,
    required this.leida,
    required this.creadoEn,
    this.enviadoEn,
  });
}
