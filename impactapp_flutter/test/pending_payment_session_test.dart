import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/features/campaigns/domain/entities/pending_payment_session.dart';

void main() {
  test('conserva los datos mínimos para reanudar una consulta pendiente', () {
    final session = PendingPaymentSession.fromMap({
      'donation_id': 21,
      'reference': 'IMPACTAPP-21-test',
      'environment': 'sandbox',
    });

    expect(session.donationId, 21);
    expect(session.reference, 'IMPACTAPP-21-test');
    expect(session.environment, 'sandbox');
    expect(session.toMap(), {
      'donation_id': 21,
      'reference': 'IMPACTAPP-21-test',
      'environment': 'sandbox',
    });
  });

  test('rechaza una sesión almacenada incompleta', () {
    expect(
      () => PendingPaymentSession.fromMap({
        'donation_id': 0,
        'reference': '',
        'environment': 'sandbox',
      }),
      throwsFormatException,
    );
  });
}
