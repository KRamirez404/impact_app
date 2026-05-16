import '../../domain/entities/donation_entity.dart';

class DonationModel extends DonationEntity {
  const DonationModel({
    required super.idDonacion,
    required super.idCampania,
    required super.idDonante,
    required super.idPunto,
    required super.tipo,
    required super.montoEstimado,
    required super.descripcion,
    required super.fechaDonacion,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      idDonacion: json['id_donacion'] ?? 0,
      idCampania: json['id_campania'] ?? 0,
      idDonante: json['id_donante'] ?? 0,
      idPunto: json['id_punto'],
      tipo: json['tipo'] ?? '',
      montoEstimado: (json['monto_estimado'] as num?)?.toDouble() ?? 0,
      descripcion: json['descripcion'],
      fechaDonacion: json['fecha_donacion'] ?? '',
    );
  }
}

