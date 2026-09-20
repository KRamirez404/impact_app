class DonationCheckoutEntity {
  final int idDonacion;
  final int idCampania;
  final String referencia;
  final double montoEstimado;
  final String estadoPago;
  final String checkoutUrl;

  const DonationCheckoutEntity({
    required this.idDonacion,
    required this.idCampania,
    required this.referencia,
    required this.montoEstimado,
    required this.estadoPago,
    required this.checkoutUrl,
  });
}
