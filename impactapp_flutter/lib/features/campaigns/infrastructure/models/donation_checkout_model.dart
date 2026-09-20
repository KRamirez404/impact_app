import '../../domain/entities/donation_checkout_entity.dart';

class DonationCheckoutModel extends DonationCheckoutEntity {
  const DonationCheckoutModel({
    required super.idDonacion,
    required super.idCampania,
    required super.referencia,
    required super.montoEstimado,
    required super.estadoPago,
    required super.checkoutUrl,
  });

  factory DonationCheckoutModel.fromJson(Map<String, dynamic> json) {
    return DonationCheckoutModel(
      idDonacion: json['id_donacion'] ?? 0,
      idCampania: json['id_campania'] ?? 0,
      referencia: json['referencia'] ?? '',
      montoEstimado: (json['monto_estimado'] as num?)?.toDouble() ?? 0,
      estadoPago: json['estado_pago'] ?? 'pendiente',
      checkoutUrl: json['checkout_url'] ?? '',
    );
  }
}
