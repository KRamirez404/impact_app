import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/core/constants/api_constants.dart';

void main() {
  tearDown(ApiConstants.restaurarBaseUrl);

  test('normaliza espacios y barras finales', () {
    expect(
      ApiConstants.normalizarBaseUrl('  http://192.168.1.10:5000/api//  '),
      'http://192.168.1.10:5000/api',
    );
  });

  test('acepta http y https terminados en /api', () {
    expect(ApiConstants.validarBaseUrl('http://192.168.1.10:5000/api'), isNull);
    expect(ApiConstants.validarBaseUrl('https://ejemplo.com/api/'), isNull);
  });

  test('rechaza URLs inválidas', () {
    expect(ApiConstants.validarBaseUrl(''), isNotNull);
    expect(ApiConstants.validarBaseUrl('192.168.1.10:5000/api'), isNotNull);
    expect(ApiConstants.validarBaseUrl('ftp://ejemplo.com/api'), isNotNull);
    expect(ApiConstants.validarBaseUrl('http://192.168.1.10:5000'), isNotNull);
  });

  test('originUrl elimina el sufijo /api para archivos públicos', () {
    ApiConstants.aplicarBaseUrl('http://192.168.1.10:5000/api');
    expect(ApiConstants.baseUrl, 'http://192.168.1.10:5000/api');
    expect(ApiConstants.originUrl, 'http://192.168.1.10:5000');
    expect(ApiConstants.login, 'http://192.168.1.10:5000/api/auth/login');
  });

  test('restaurarBaseUrl vuelve al valor compilado', () {
    ApiConstants.aplicarBaseUrl('http://10.0.0.5:5000/api');
    ApiConstants.restaurarBaseUrl();
    expect(ApiConstants.baseUrl, ApiConstants.defaultBaseUrl);
  });
}
