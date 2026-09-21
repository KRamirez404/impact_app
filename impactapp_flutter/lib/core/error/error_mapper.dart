import 'package:dio/dio.dart';

import 'exceptions.dart';

const String defaultErrorMessage =
    'Ocurrió un error inesperado. Intenta nuevamente.';

String friendlyError(
  Object error, {
  String fallback = defaultErrorMessage,
}) {
  if (error is ServerException) return error.message;
  if (error is UnauthorizedException) return error.message;
  if (error is DioException) return _fromDio(error);

  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? fallback : text;
}

String _fromDio(DioException error) {
  final serverMessage = _serverMessage(error.response?.data);
  if (serverMessage != null && serverMessage.isNotEmpty) {
    return serverMessage;
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'El servidor tardó demasiado en responder. Verifica tu conexión e intenta de nuevo.';
    case DioExceptionType.connectionError:
      return 'No se pudo conectar con el servidor. Revisa tu conexión a internet.';
    case DioExceptionType.badCertificate:
      return 'No se pudo verificar la seguridad del servidor.';
    case DioExceptionType.cancel:
      return 'La solicitud fue cancelada.';
    case DioExceptionType.badResponse:
      return _fromStatus(error.response?.statusCode);
    case DioExceptionType.unknown:
      return 'No se pudo completar la solicitud. Revisa tu conexión e intenta de nuevo.';
  }
}

String? _serverMessage(dynamic data) {
  if (data is Map) {
    final message = data['error'] ?? data['message'];
    if (message != null) {
      final text = message.toString().trim();
      if (text.isNotEmpty) return text;
    }
  }
  if (data is String && data.trim().isNotEmpty) {
    return data.trim();
  }
  return null;
}

String _fromStatus(int? status) {
  switch (status) {
    case 400:
      return 'Los datos enviados no son válidos. Revisa la información e intenta de nuevo.';
    case 401:
      return 'Tu sesión expiró o las credenciales son incorrectas. Inicia sesión nuevamente.';
    case 403:
      return 'No tienes permisos para realizar esta acción.';
    case 404:
      return 'No encontramos la información solicitada.';
    case 409:
      return 'La operación entra en conflicto con datos existentes.';
    case 413:
      return 'El archivo es demasiado grande.';
    case 422:
      return 'Algunos datos no son válidos. Revisa la información.';
    case 429:
      return 'Demasiadas solicitudes. Espera un momento e intenta de nuevo.';
    case 500:
      return 'Ocurrió un error en el servidor. Intenta más tarde.';
    case 502:
    case 503:
      return 'El servicio no está disponible en este momento. Intenta más tarde.';
    case 504:
      return 'El servidor no respondió a tiempo. Intenta de nuevo.';
    default:
      return 'No se pudo completar la solicitud. Intenta de nuevo.';
  }
}
