import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';

String transferFriendlyError(Object error, {bool loadingAccount = false}) {
  if (loadingAccount &&
      error is DioException &&
      error.response?.statusCode == 404) {
    return 'La campaña no tiene una cuenta verificada o el módulo de transferencias está deshabilitado.';
  }
  return friendlyError(error);
}
