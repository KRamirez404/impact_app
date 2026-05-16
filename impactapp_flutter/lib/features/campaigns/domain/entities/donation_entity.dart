class DonationEntity {
  final int idDonacion;
  final int idCampania;
  final int idDonante;
  final int? idPunto;
  final String tipo;
  final double montoEstimado;
  final String? descripcion;
  final String fechaDonacion;

  const DonationEntity({
    required this.idDonacion,
    required this.idCampania,
    required this.idDonante,
    required this.idPunto,
    required this.tipo,
    required this.montoEstimado,
    required this.descripcion,
    required this.fechaDonacion,
  });
}

