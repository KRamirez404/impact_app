import '../../domain/entities/support_entity.dart';

class SupportModel extends SupportEntity {
  const SupportModel({
    required super.idSoporte,
    required super.idCampania,
    required super.tipo,
    required super.urlORuta,
    required super.descripcion,
    required super.validado,
  });

  factory SupportModel.fromJson(Map<String, dynamic> json) {
    return SupportModel(
      idSoporte: json['id_soporte'] ?? 0,
      idCampania: json['id_campania'] ?? 0,
      tipo: json['tipo'] ?? '',
      urlORuta: json['url_o_ruta'] ?? '',
      descripcion: json['descripcion'],
      validado: json['validado'] ?? false,
    );
  }
}

