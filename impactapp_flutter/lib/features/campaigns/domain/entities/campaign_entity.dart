class CampaignEntity {
  final int idCampania;
  final String titulo;
  final String descripcion;
  final int idCiudad;
  final int idCategoria;
  final int idCreador;
  final String tipoAyudaRequerida;
  final double metaMonetaria;
  final String fechaInicio;
  final String fechaFin;
  final String estado;
  final double porcentajeAvance;
  final List<Map<String, dynamic>> valoraciones;
  final List<Map<String, dynamic>> soportes;
  final List<Map<String, dynamic>> puntosRecoleccion;

  const CampaignEntity({
    required this.idCampania,
    required this.titulo,
    required this.descripcion,
    required this.idCiudad,
    required this.idCategoria,
    required this.idCreador,
    required this.tipoAyudaRequerida,
    required this.metaMonetaria,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.porcentajeAvance,
    this.valoraciones = const [],
    this.soportes = const [],
    this.puntosRecoleccion = const [],
  });
}
