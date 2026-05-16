import '../../domain/entities/collection_point_entity.dart';

class CollectionPointModel extends CollectionPointEntity {
  const CollectionPointModel({
    required super.idPunto,
    required super.idCampania,
    required super.idCiudad,
    required super.nombre,
    required super.direccion,
    required super.horario,
    required super.contacto,
  });

  factory CollectionPointModel.fromJson(Map<String, dynamic> json) {
    return CollectionPointModel(
      idPunto: json['id_punto'] ?? 0,
      idCampania: json['id_campania'] ?? 0,
      idCiudad: json['id_ciudad'] ?? 0,
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
      horario: json['horario'] ?? '',
      contacto: json['contacto'] ?? '',
    );
  }
}

