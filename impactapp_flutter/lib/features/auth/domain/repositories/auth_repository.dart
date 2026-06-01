import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<String> login(String correo, String contrasena);
  Future<UserEntity> register({
    required String nombre,
    required String apellido,
    required String correo,
    required String contrasena,
    String? telefono,
  });
  Future<UserEntity> me();
  Future<UserEntity> updateProfile({
    required String nombre,
    required String apellido,
    required String correo,
    String? telefono,
    String? biografia,
  });
}
