import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';
import '../network/dio_client.dart';

class ServerConfig {
  static GetStorage get _storage => GetStorage();

  static String get baseUrl => ApiConstants.baseUrl;

  static void cargarGuardada() {
    final guardada = _storage.read<String>(StorageKeys.apiBaseUrl);
    if (guardada == null || guardada.isEmpty) {
      return;
    }
    if (ApiConstants.validarBaseUrl(guardada) != null) {
      return;
    }
    ApiConstants.aplicarBaseUrl(guardada);
  }

  static Future<bool> guardar(String valor) async {
    if (ApiConstants.validarBaseUrl(valor) != null) {
      return false;
    }
    final normalizada = ApiConstants.normalizarBaseUrl(valor);
    ApiConstants.aplicarBaseUrl(normalizada);
    await _storage.write(StorageKeys.apiBaseUrl, normalizada);
    _storage.remove(StorageKeys.token);
    _storage.remove(StorageKeys.user);
    DioClient.instance.dio.options.baseUrl = ApiConstants.baseUrl;
    return true;
  }

  static Future<void> restaurar() async {
    ApiConstants.restaurarBaseUrl();
    await _storage.remove(StorageKeys.apiBaseUrl);
    _storage.remove(StorageKeys.token);
    _storage.remove(StorageKeys.user);
    DioClient.instance.dio.options.baseUrl = ApiConstants.baseUrl;
  }

  static Future<String?> verificarConexion() async {
    try {
      final response = await DioClient.instance.dio.get(
        ApiConstants.health,
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
        ),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final estado = response.data['status'];
        final baseDatos = response.data['database'];
        if (estado == 'ok') {
          return baseDatos == 'ok'
              ? null
              : 'El servidor responde, pero la base de datos no está disponible';
        }
      }
      return 'El servidor respondió con un estado inesperado';
    } on DioException catch (error) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Tiempo de espera agotado al conectar con el servidor';
        case DioExceptionType.badResponse:
          return 'El servidor respondió con código ${error.response?.statusCode}';
        case DioExceptionType.connectionError:
          return 'No se pudo conectar. Verifica la IP, el puerto y la red Wi-Fi';
        default:
          return 'No se pudo conectar con el servidor';
      }
    } catch (_) {
      return 'No se pudo conectar con el servidor';
    }
  }
}
