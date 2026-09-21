import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/core/error/error_mapper.dart';
import 'package:impactapp_flutter/core/error/exceptions.dart';

DioException _dioError({
  int? statusCode,
  dynamic data,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final options = RequestOptions(path: '/api/test');
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null && data == null
        ? null
        : Response(
            requestOptions: options,
            statusCode: statusCode,
            data: data,
          ),
  );
}

void main() {
  test('prioriza el mensaje de error del backend', () {
    final error = _dioError(
      statusCode: 503,
      data: {'error': 'Las donaciones en línea no están disponibles.'},
    );
    expect(friendlyError(error), 'Las donaciones en línea no están disponibles.');
  });

  test('usa data["message"] si no hay "error"', () {
    final error = _dioError(statusCode: 400, data: {'message': 'Dato inválido'});
    expect(friendlyError(error), 'Dato inválido');
  });

  test('mapea 401 a mensaje de sesión', () {
    expect(friendlyError(_dioError(statusCode: 401)), contains('sesión'));
  });

  test('mapea 403 a permisos', () {
    expect(friendlyError(_dioError(statusCode: 403)), contains('permisos'));
  });

  test('mapea 404 a no encontrado', () {
    expect(friendlyError(_dioError(statusCode: 404)), contains('encontramos'));
  });

  test('mapea 500 a error de servidor', () {
    expect(friendlyError(_dioError(statusCode: 500)), contains('servidor'));
  });

  test('mapea error de conexión', () {
    final error = _dioError(type: DioExceptionType.connectionError);
    expect(friendlyError(error), contains('conectar'));
  });

  test('mapea timeout', () {
    final error = _dioError(type: DioExceptionType.connectionTimeout);
    expect(friendlyError(error), contains('tardó'));
  });

  test('usa el mensaje de ServerException', () {
    expect(
      friendlyError(ServerException('Respuesta inválida del servidor')),
      'Respuesta inválida del servidor',
    );
  });

  test('limpia el prefijo Exception: de errores genéricos', () {
    expect(friendlyError(Exception('Algo falló')), 'Algo falló');
  });

  test('usa fallback para errores sin texto', () {
    expect(friendlyError(Exception('')), defaultErrorMessage);
  });
}
