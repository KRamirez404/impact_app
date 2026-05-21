import '../../domain/entities/top_donor_entity.dart';

class TopDonorModel extends TopDonorEntity {
  const TopDonorModel({
    required super.idUsuario,
    required super.nombre,
    required super.apellido,
    required super.totalDonado,
    required super.donacionesCount,
  });

  factory TopDonorModel.fromJson(Map<String, dynamic> json) {
    return TopDonorModel(
      idUsuario: json['id_usuario'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      totalDonado: (json['total_donado'] as num?)?.toDouble() ?? 0,
      donacionesCount: json['donaciones_count'] ?? 0,
    );
  }
}
