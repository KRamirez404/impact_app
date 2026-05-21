class DonorWithDonationEntity {
  final int idDonacion;
  final int idCampania;
  final int idDonante;
  final int? idPunto;
  final String tipo;
  final double montoEstimado;
  final String? descripcion;
  final String fechaDonacion;
  final String nombreDonante;
  final String apellidoDonante;
  final String correoDonante;
  final bool esAnonimo;

  const DonorWithDonationEntity({
    required this.idDonacion,
    required this.idCampania,
    required this.idDonante,
    required this.idPunto,
    required this.tipo,
    required this.montoEstimado,
    required this.descripcion,
    required this.fechaDonacion,
    required this.nombreDonante,
    required this.apellidoDonante,
    required this.correoDonante,
    this.esAnonimo = false,
  });

  String get nombreCompleto {
    if (esAnonimo) return '🎭 Donante Anónimo';
    return '$nombreDonante $apellidoDonante'.trim();
  }

  bool get esDonacionFisica => tipo != 'economica';
}
