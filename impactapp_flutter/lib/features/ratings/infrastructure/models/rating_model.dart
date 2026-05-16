import '../../domain/entities/rating_entity.dart';

class RatingModel extends RatingEntity {
  const RatingModel({
    required super.idValoracion,
    required super.idCampania,
    required super.idUsuario,
    required super.calificacion,
    required super.comentario,
    required super.visible,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      idValoracion: json['id_valoracion'] ?? 0,
      idCampania: json['id_campania'] ?? 0,
      idUsuario: json['id_usuario'] ?? 0,
      calificacion: json['calificacion'] ?? 0,
      comentario: json['comentario'],
      visible: json['visible'] ?? true,
    );
  }
}

