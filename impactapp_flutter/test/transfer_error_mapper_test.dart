import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/features/transfers/presentation/controllers/transfer_error_mapper.dart';

void main() {
  test('explica un 404 del endpoint de cuenta sin simular disponibilidad', () {
    final request = RequestOptions(path: '/campaigns/7/bank-account');
    final error = DioException(
      requestOptions: request,
      response: Response(requestOptions: request, statusCode: 404),
      type: DioExceptionType.badResponse,
    );

    expect(
      transferFriendlyError(error, loadingAccount: true),
      'La campaña no tiene una cuenta verificada o el módulo de transferencias está deshabilitado.',
    );
  });

  test('conserva el mensaje seguro enviado por el backend en 503', () {
    final request = RequestOptions(path: '/transfers');
    final error = DioException(
      requestOptions: request,
      response: Response(
        requestOptions: request,
        statusCode: 503,
        data: {
          'error': 'El módulo de transferencias no está disponible',
          'code': 'transfer_feature_disabled',
        },
      ),
      type: DioExceptionType.badResponse,
    );

    expect(
      transferFriendlyError(error),
      'El módulo de transferencias no está disponible',
    );
  });
}
