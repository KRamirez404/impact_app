import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  Map<String, dynamic> _safeData(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) {
      throw ServerException('Respuesta inválida del servidor');
    }
    return data;
  }

  Future<(String, UserModel)> login(String correo, String contrasena) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'correo': correo, 'contrasena': contrasena},
    );
    final data = _safeData(response.data);
    return (
      data['access_token'] as String? ?? '',
      UserModel.fromJson(data['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Future<UserModel> register({
    required String nombre,
    required String apellido,
    required String correo,
    required String contrasena,
    String? telefono,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'contrasena': contrasena,
        'telefono': telefono,
      },
    );
    final data = _safeData(response.data);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>? ?? {});
  }

  Future<UserModel> me() async {
    final response = await _dio.get(ApiConstants.me);
    return UserModel.fromJson(_safeData(response.data));
  }

  Future<UserModel> updateProfile({
    required String nombre,
    required String apellido,
    required String correo,
    String? telefono,
    String? biografia,
  }) async {
    final response = await _dio.put(
      ApiConstants.me,
      data: {
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'telefono': telefono,
        'biografia': biografia,
      },
    );
    return UserModel.fromJson(_safeData(response.data));
  }
}
