class PendingPaymentSession {
  final int donationId;
  final String reference;
  final String environment;

  const PendingPaymentSession({
    required this.donationId,
    required this.reference,
    required this.environment,
  });

  factory PendingPaymentSession.fromMap(Map<String, dynamic> map) {
    final donationId = map['donation_id'];
    final reference = map['reference'];
    final environment = map['environment'];
    if (donationId is! int ||
        donationId <= 0 ||
        reference is! String ||
        reference.isEmpty ||
        environment is! String ||
        environment.isEmpty) {
      throw const FormatException('Sesión de pago pendiente inválida');
    }
    return PendingPaymentSession(
      donationId: donationId,
      reference: reference,
      environment: environment,
    );
  }

  Map<String, dynamic> toMap() => {
    'donation_id': donationId,
    'reference': reference,
    'environment': environment,
  };
}
