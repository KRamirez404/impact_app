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
    super.campaignImageUrl,
  });

  factory DonationWithCampaignModel.fromJson(Map<String, dynamic> json) {
    final campaign = json['campania'] as Map<String, dynamic>? ?? const {};
    final soportes = campaign['soportes'] as List<dynamic>? ?? [];
    String? imageUrl;
    for (final s in soportes) {
      final tipo = (s['tipo'] ?? '').toString().toLowerCase().trim();
      if (tipo == 'foto' || tipo == 'imagen') {
        final url = (s['url_o_ruta'] ?? '').toString().trim();
        if (url.isNotEmpty) {
          imageUrl = url;
          break;
        }
      }
    }
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
      campaignImageUrl: imageUrl,
    );
  }
}
