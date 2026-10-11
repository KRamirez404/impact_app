import '../../domain/entities/city_entity.dart';

class CityModel extends CityEntity {
  const CityModel({required super.idCiudad, required super.nombre});

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
    idCiudad: json['id_ciudad'] as int,
    nombre: json['nombre'] as String,
  );
}
