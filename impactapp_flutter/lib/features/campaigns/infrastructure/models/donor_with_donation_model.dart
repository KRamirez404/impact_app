import '../../domain/entities/donor_with_donation_entity.dart';

class DonorWithDonationModel extends DonorWithDonationEntity {
  const DonorWithDonationModel({
    required super.idDonacion,
    required super.idCampania,
    required super.idDonante,
    required super.idPunto,
    required super.tipo,
    required super.montoEstimado,
    required super.descripcion,
    required super.fechaDonacion,
    required super.nombreDonante,
    required super.apellidoDonante,
    required super.correoDonante,
    required super.esAnonimo,
  });

  factory DonorWithDonationModel.fromJson(Map<String, dynamic> json) {
    final donante = json['donante'] as Map<String, dynamic>? ?? const {};
    return DonorWithDonationModel(
      idDonacion: json['id_donacion'] ?? 0,
      idCampania: json['id_campania'] ?? 0,
      idDonante: json['id_donante'] ?? 0,
      idPunto: json['id_punto'],
      tipo: json['tipo'] ?? '',
      montoEstimado: (json['monto_estimado'] as num?)?.toDouble() ?? 0,
      descripcion: json['descripcion'],
      fechaDonacion: json['fecha_donacion'] ?? '',
      nombreDonante: donante['nombre'] ?? '',
      apellidoDonante: donante['apellido'] ?? '',
      correoDonante: donante['correo'] ?? '',
      esAnonimo: json['es_anonimo'] == true || json['es_anonimo'] == 1,
    );
  }
}
