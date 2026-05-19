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
  final String ciudadNombre;
  final String categoriaNombre;
  final int donantesCount;
  final int puntosCount;
  final int vistasCount;
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
    this.ciudadNombre = '',
    this.categoriaNombre = '',
    this.donantesCount = 0,
    this.puntosCount = 0,
    this.vistasCount = 0,
    this.valoraciones = const [],
    this.soportes = const [],
    this.puntosRecoleccion = const [],
  });
}
