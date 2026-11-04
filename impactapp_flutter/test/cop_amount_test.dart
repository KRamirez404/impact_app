import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/core/utils/cop_amount.dart';

void main() {
  test('convierte enteros y formatos COP a centavos exactos', () {
    expect(parseCopAmount('50000').cents, 5000000);
    expect(parseCopAmount('50.000').cents, 5000000);
    expect(parseCopAmount('1.000.000').cents, 100000000);
    expect(parseCopAmount('50000.50').cents, 5000050);
    expect(parseCopAmount('50.000,50').cents, 5000050);
    expect(parseCopAmount('1000').cents, 100000);
    expect(parseCopAmount('9999999999.99').cents, maxDonationCents);
    expect(parseCopAmount('\$ 50.000').cents, 5000000);
  });

  test('rechaza importes ambiguos o fuera de rango', () {
    expect(parseCopAmount('').isValid, isFalse);
    expect(parseCopAmount('NaN').isValid, isFalse);
    expect(parseCopAmount('999').isValid, isFalse);
    expect(parseCopAmount('1.234,567').isValid, isFalse);
    expect(parseCopAmount('0.500').isValid, isFalse);
    expect(parseCopAmount('10000000000').isValid, isFalse);
    expect(parseCopAmount('50,000').isValid, isFalse);
  });

  test('formatea el valor que viaja al API', () {
    expect(formatCopAmountForApi(5000000), '50000.00');
    expect(formatCopAmountForApi(5000050), '50000.50');
    expect(formatCopAmountForApi(100), '1.00');
    expect(formatCopAmount(5000050), '\$50.000,50');
  });

  test('genera claves de idempotencia válidas y distintas', () {
    final keys = List<String>.generate(100, (_) => newIdempotencyKey());
    expect(keys.toSet().length, keys.length);
    for (final key in keys) {
      expect(key.length, lessThanOrEqualTo(128));
      expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(key), isTrue);
    }
  });
}
