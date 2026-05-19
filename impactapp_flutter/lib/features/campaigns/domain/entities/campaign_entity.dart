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
  final String creadorNombre;
  final String creadorApellido;
  final String creadorCorreo;
  final String? creadorTelefono;
  final int donantesCount;
  final int puntosCount;
  final int vistasCount;
  final List<Map<String, dynamic>> valoraciones;
  final List<Map<String, dynamic>> soportes;
  final List<Map<String, dynamic>> puntosRecoleccion;
  final List<Map<String, dynamic>> seguimientos;

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
    this.creadorNombre = '',
    this.creadorApellido = '',
    this.creadorCorreo = '',
    this.creadorTelefono,
    this.donantesCount = 0,
    this.puntosCount = 0,
    this.vistasCount = 0,
    this.valoraciones = const [],
    this.soportes = const [],
    this.puntosRecoleccion = const [],
    this.seguimientos = const [],
  });

  CampaignEntity copyWith({
    int? idCampania,
    String? titulo,
    String? descripcion,
    int? idCiudad,
    int? idCategoria,
    int? idCreador,
    String? tipoAyudaRequerida,
    double? metaMonetaria,
    String? fechaInicio,
    String? fechaFin,
    String? estado,
    double? porcentajeAvance,
    String? ciudadNombre,
    String? categoriaNombre,
    String? creadorNombre,
    String? creadorApellido,
    String? creadorCorreo,
    String? creadorTelefono,
    int? donantesCount,
    int? puntosCount,
    int? vistasCount,
    List<Map<String, dynamic>>? valoraciones,
    List<Map<String, dynamic>>? soportes,
    List<Map<String, dynamic>>? puntosRecoleccion,
    List<Map<String, dynamic>>? seguimientos,
  }) {
    return CampaignEntity(
      idCampania: idCampania ?? this.idCampania,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      idCiudad: idCiudad ?? this.idCiudad,
      idCategoria: idCategoria ?? this.idCategoria,
      idCreador: idCreador ?? this.idCreador,
      tipoAyudaRequerida: tipoAyudaRequerida ?? this.tipoAyudaRequerida,
      metaMonetaria: metaMonetaria ?? this.metaMonetaria,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
      porcentajeAvance: porcentajeAvance ?? this.porcentajeAvance,
      ciudadNombre: ciudadNombre ?? this.ciudadNombre,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      creadorNombre: creadorNombre ?? this.creadorNombre,
      creadorApellido: creadorApellido ?? this.creadorApellido,
      creadorCorreo: creadorCorreo ?? this.creadorCorreo,
      creadorTelefono: creadorTelefono ?? this.creadorTelefono,
      donantesCount: donantesCount ?? this.donantesCount,
      puntosCount: puntosCount ?? this.puntosCount,
      vistasCount: vistasCount ?? this.vistasCount,
      valoraciones: valoraciones ?? this.valoraciones,
      soportes: soportes ?? this.soportes,
      puntosRecoleccion: puntosRecoleccion ?? this.puntosRecoleccion,
      seguimientos: seguimientos ?? this.seguimientos,
    );
  }
}
