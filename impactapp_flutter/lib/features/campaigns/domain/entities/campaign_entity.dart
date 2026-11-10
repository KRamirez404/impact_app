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
  final String? cuentaRecaudo;
  final String ciudadNombre;
  final String categoriaNombre;
  final String creadorNombre;
  final String creadorApellido;
  final String creadorCorreo;
  final String? creadorTelefono;
  final String? instagramUrl;
  final String? facebookUrl;
  final String? tiktokUrl;
  final Map<String, dynamic> creadorRedesSociales;
  final String? notaRevision;
  final String? fechaRevision;
  final String? auditorNombre;
  final String? auditorApellido;
  final String? auditorCorreo;
  final bool eliminada;
  final String? motivoEliminacion;
  final String? fechaEliminacion;
  final int donantesCount;
  final int puntosCount;
  final int vistasCount;
  final int likesCount;
  final bool likedByMe;
  final List<Map<String, dynamic>> valoraciones;
  final List<Map<String, dynamic>> soportes;
  final List<Map<String, dynamic>> puntosRecoleccion;
  final List<Map<String, dynamic>> seguimientos;
  final Map<String, dynamic>? informeFinanciero;

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
    this.cuentaRecaudo,
    this.ciudadNombre = '',
    this.categoriaNombre = '',
    this.creadorNombre = '',
    this.creadorApellido = '',
    this.creadorCorreo = '',
    this.creadorTelefono,
    this.instagramUrl,
    this.facebookUrl,
    this.tiktokUrl,
    this.creadorRedesSociales = const {},
    this.notaRevision,
    this.fechaRevision,
    this.auditorNombre,
    this.auditorApellido,
    this.auditorCorreo,
    this.eliminada = false,
    this.motivoEliminacion,
    this.fechaEliminacion,
    this.donantesCount = 0,
    this.puntosCount = 0,
    this.vistasCount = 0,
    this.likesCount = 0,
    this.likedByMe = false,
    this.valoraciones = const [],
    this.soportes = const [],
    this.puntosRecoleccion = const [],
    this.seguimientos = const [],
    this.informeFinanciero,
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
    String? cuentaRecaudo,
    String? ciudadNombre,
    String? categoriaNombre,
    String? creadorNombre,
    String? creadorApellido,
    String? creadorCorreo,
    String? creadorTelefono,
    String? instagramUrl,
    String? facebookUrl,
    String? tiktokUrl,
    Map<String, dynamic>? creadorRedesSociales,
    String? notaRevision,
    String? fechaRevision,
    String? auditorNombre,
    String? auditorApellido,
    String? auditorCorreo,
    bool? eliminada,
    String? motivoEliminacion,
    String? fechaEliminacion,
    int? donantesCount,
    int? puntosCount,
    int? vistasCount,
    int? likesCount,
    bool? likedByMe,
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
      cuentaRecaudo: cuentaRecaudo ?? this.cuentaRecaudo,
      ciudadNombre: ciudadNombre ?? this.ciudadNombre,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      creadorNombre: creadorNombre ?? this.creadorNombre,
      creadorApellido: creadorApellido ?? this.creadorApellido,
      creadorCorreo: creadorCorreo ?? this.creadorCorreo,
      creadorTelefono: creadorTelefono ?? this.creadorTelefono,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      creadorRedesSociales: creadorRedesSociales ?? this.creadorRedesSociales,
      notaRevision: notaRevision ?? this.notaRevision,
      fechaRevision: fechaRevision ?? this.fechaRevision,
      auditorNombre: auditorNombre ?? this.auditorNombre,
      auditorApellido: auditorApellido ?? this.auditorApellido,
      auditorCorreo: auditorCorreo ?? this.auditorCorreo,
      eliminada: eliminada ?? this.eliminada,
      motivoEliminacion: motivoEliminacion ?? this.motivoEliminacion,
      fechaEliminacion: fechaEliminacion ?? this.fechaEliminacion,
      donantesCount: donantesCount ?? this.donantesCount,
      puntosCount: puntosCount ?? this.puntosCount,
      vistasCount: vistasCount ?? this.vistasCount,
      likesCount: likesCount ?? this.likesCount,
      likedByMe: likedByMe ?? this.likedByMe,
      valoraciones: valoraciones ?? this.valoraciones,
      soportes: soportes ?? this.soportes,
      puntosRecoleccion: puntosRecoleccion ?? this.puntosRecoleccion,
      seguimientos: seguimientos ?? this.seguimientos,
      informeFinanciero: informeFinanciero ?? this.informeFinanciero,
    );
  }
}
