import '../../domain/entities/support_summary_entity.dart';

class SupportSummaryModel extends SupportSummaryEntity {
  const SupportSummaryModel({
    required super.pendientes,
    required super.aprobadas,
    required super.rechazadas,
    super.eliminadas = 0,
  });

  factory SupportSummaryModel.fromJson(Map<String, dynamic> json) {
    return SupportSummaryModel(
      pendientes: (json['pendientes'] ?? 0) as int,
      aprobadas: (json['aprobadas'] ?? 0) as int,
      rechazadas: (json['rechazadas'] ?? 0) as int,
      eliminadas: (json['eliminadas'] ?? 0) as int,
    );
  }
}
