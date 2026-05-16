class RatingEntity {
  final int idValoracion;
  final int idCampania;
  final int idUsuario;
  final int calificacion;
  final String? comentario;
  final bool visible;

  const RatingEntity({
    required this.idValoracion,
    required this.idCampania,
    required this.idUsuario,
    required this.calificacion,
    required this.comentario,
    required this.visible,
  });
}

