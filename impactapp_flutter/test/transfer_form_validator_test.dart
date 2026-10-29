import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/features/transfers/presentation/controllers/transfer_form_validator.dart';

void main() {
  test('acepta importe COP, referencia y fecha válida', () {
    final result = TransferFormValidator.validate(
      amount: '50000.50',
      reference: ' REF 123 ',
      transferDate: DateTime(2026, 10, 21),
      today: DateTime(2026, 10, 22),
    );

    expect(result.error, isNull);
    expect(result.amountForApi, '50000.50');
    expect(result.reference, 'REF 123');
    expect(result.dateForApi, '2026-10-21');
  });

  test('rechaza una fecha futura', () {
    final result = TransferFormValidator.validate(
      amount: '50000',
      reference: 'REF-123',
      transferDate: DateTime(2026, 10, 23),
      today: DateTime(2026, 10, 22),
    );

    expect(result.error, 'La fecha no puede ser futura');
  });

  test('rechaza importe con más de dos decimales', () {
    final result = TransferFormValidator.validate(
      amount: '1000.001',
      reference: 'REF-123',
      transferDate: DateTime(2026, 10, 22),
      today: DateTime(2026, 10, 22),
    );

    expect(result.error, 'El monto admite máximo dos decimales');
  });
}
