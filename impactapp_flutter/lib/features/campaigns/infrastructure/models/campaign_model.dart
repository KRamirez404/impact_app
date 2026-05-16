import '../../domain/entities/campaign_entity.dart';

class CampaignModel extends CampaignEntity {
  const CampaignModel({
    required super.idCampania,
    required super.titulo,
    required super.descripcion,
    required super.idCiudad,
    required super.idCategoria,
    required super.idCreador,
    required super.tipoAyudaRequerida,
    required super.metaMonetaria,
    required super.fechaInicio,
    required super.fechaFin,
    required super.estado,
    required super.porcentajeAvance,
    super.valoraciones = const [],
    super.soportes = const [],
    super.puntosRecoleccion = const [],
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      idCampania: json['id_campania'] ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      idCiudad: json['id_ciudad'] ?? 0,
      idCategoria: json['id_categoria'] ?? 0,
      idCreador: json['id_creador'] ?? 0,
      tipoAyudaRequerida: json['tipo_ayuda_requerida'] ?? '',
      metaMonetaria: (json['meta_monetaria'] as num?)?.toDouble() ?? 0,
      fechaInicio: json['fecha_inicio'] ?? '',
      fechaFin: json['fecha_fin'] ?? '',
      estado: json['estado'] ?? '',
      porcentajeAvance: (json['porcentaje_avance'] as num?)?.toDouble() ?? 0,
      valoraciones: (json['valoraciones'] as List<dynamic>? ?? [])
          .map((e) => (e as Map<String, dynamic>))
          .toList(),
      soportes: (json['soportes'] as List<dynamic>? ?? [])
          .map((e) => (e as Map<String, dynamic>))
          .toList(),
      puntosRecoleccion: (json['puntos_recoleccion'] as List<dynamic>? ?? [])
          .map((e) => (e as Map<String, dynamic>))
          .toList(),
    );
  }
}
