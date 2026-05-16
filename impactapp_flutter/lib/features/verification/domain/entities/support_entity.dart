class SupportEntity {
  final int idSoporte;
  final int idCampania;
  final String tipo;
  final String urlORuta;
  final String? descripcion;
  final bool validado;

  const SupportEntity({
    required this.idSoporte,
    required this.idCampania,
    required this.tipo,
    required this.urlORuta,
    required this.descripcion,
    required this.validado,
  });
}

