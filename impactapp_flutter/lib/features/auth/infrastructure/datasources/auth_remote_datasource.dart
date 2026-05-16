import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  Future<(String, UserModel)> login(String correo, String contrasena) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'correo': correo, 'contrasena': contrasena},
    );
    return (
      response.data['access_token'] as String,
      UserModel.fromJson(response.data['user'] as Map<String, dynamic>)
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
    return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> me() async {
    final response = await _dio.get(ApiConstants.me);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}

