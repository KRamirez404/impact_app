class DonationCheckoutEntity {
  final int idDonacion;
  final int idCampania;
  final String referencia;
  final double montoEstimado;
  final int montoEnCentavos;
  final String estadoPago;
  final String ambiente;
  final String checkoutUrl;

  const DonationCheckoutEntity({
    required this.idDonacion,
    required this.idCampania,
    required this.referencia,
    required this.montoEstimado,
    required this.estadoPago,
    required this.checkoutUrl,
    this.montoEnCentavos = 0,
    this.ambiente = 'sandbox',
  });
}
