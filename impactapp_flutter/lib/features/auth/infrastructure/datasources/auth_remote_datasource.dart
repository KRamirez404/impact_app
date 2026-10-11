import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';
import '../models/city_model.dart';

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
    String? rol,
    bool aceptaTratamiento = false,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'contrasena': contrasena,
        'telefono': telefono,
        'rol': rol,
        'acepta_tratamiento': aceptaTratamiento,
      },
    );
    final data = _safeData(response.data);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>? ?? {});
  }

  Future<void> deleteAccount() async {
    await _dio.delete(ApiConstants.me);
  }

  Future<UserModel> me() async {
    final response = await _dio.get(ApiConstants.me);
    return UserModel.fromJson(_safeData(response.data));
  }

  Future<List<CityModel>> getCities() async {
    final response = await _dio.get(ApiConstants.cities);
    if (response.data is! List) {
      throw ServerException('Respuesta inválida del servidor');
    }
    return (response.data as List)
        .map((item) => CityModel.fromJson(_safeData(item)))
        .toList();
  }

  Future<UserModel> updateProfile({
    required String nombre,
    required String apellido,
    required String correo,
    String? telefono,
    String? biografia,
    String? fotoPerfil,
    int? idCiudad,
  }) async {
    final response = await _dio.put(
      ApiConstants.me,
      data: {
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'telefono': telefono,
        'biografia': biografia,
        'foto_perfil': fotoPerfil,
        'id_ciudad': idCiudad,
      },
    );
    return UserModel.fromJson(_safeData(response.data));
  }
}
