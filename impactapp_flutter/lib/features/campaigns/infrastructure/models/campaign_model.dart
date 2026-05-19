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
    super.ciudadNombre = '',
    super.categoriaNombre = '',
    super.creadorNombre = '',
    super.creadorApellido = '',
    super.creadorCorreo = '',
    super.creadorTelefono,
    super.donantesCount = 0,
    super.puntosCount = 0,
    super.vistasCount = 0,
    super.valoraciones = const [],
    super.soportes = const [],
    super.puntosRecoleccion = const [],
    super.seguimientos = const [],
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    final ciudad = json['ciudad'] as Map<String, dynamic>?;
    final categoria = json['categoria'] as Map<String, dynamic>?;
    final creador = json['creador'] as Map<String, dynamic>?;

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
      ciudadNombre: ciudad?['nombre'] ?? '',
      categoriaNombre: categoria?['nombre'] ?? '',
      creadorNombre: creador?['nombre'] ?? '',
      creadorApellido: creador?['apellido'] ?? '',
      creadorCorreo: creador?['correo'] ?? '',
      creadorTelefono: creador?['telefono'],
      donantesCount: json['donantes_count'] ?? (json['donaciones'] as List? ?? []).length,
      puntosCount: (json['puntos_recoleccion'] as List? ?? []).length,
      vistasCount: json['vistas_count'] ?? 0,
      valoraciones: (json['valoraciones'] as List<dynamic>? ?? [])
          .map((e) => (e as Map<String, dynamic>))
          .toList(),
      soportes: (json['soportes'] as List<dynamic>? ?? [])
          .map((e) => (e as Map<String, dynamic>))
          .toList(),
      puntosRecoleccion: (json['puntos_recoleccion'] as List<dynamic>? ?? [])
          .map((e) => (e as Map<String, dynamic>))
          .toList(),
      seguimientos: (json['seguimientos'] as List<dynamic>? ?? [])
          .map((e) => (e as Map<String, dynamic>))
          .toList(),
    );
  }
}
