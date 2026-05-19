import '../../domain/entities/donation_with_campaign_entity.dart';

class DonationWithCampaignModel extends DonationWithCampaignEntity {
  const DonationWithCampaignModel({
    required super.idDonacion,
    required super.idCampania,
    required super.idDonante,
    required super.idPunto,
    required super.tipo,
    required super.montoEstimado,
    required super.descripcion,
    required super.fechaDonacion,
    required super.campaignTitulo,
    required super.campaignEstado,
    required super.campaignFechaFin,
  });

  factory DonationWithCampaignModel.fromJson(Map<String, dynamic> json) {
    final campaign = json['campania'] as Map<String, dynamic>? ?? const {};
    return DonationWithCampaignModel(
      idDonacion: json['id_donacion'] ?? 0,
      idCampania: json['id_campania'] ?? 0,
      idDonante: json['id_donante'] ?? 0,
      idPunto: json['id_punto'],
      tipo: json['tipo'] ?? '',
      montoEstimado: (json['monto_estimado'] as num?)?.toDouble() ?? 0,
      descripcion: json['descripcion'],
      fechaDonacion: json['fecha_donacion'] ?? '',
      campaignTitulo: campaign['titulo'] ?? '',
      campaignEstado: campaign['estado'] ?? '',
      campaignFechaFin: campaign['fecha_fin'] ?? '',
    );
  }
}
