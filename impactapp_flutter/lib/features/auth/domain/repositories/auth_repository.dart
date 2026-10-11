import '../entities/user_entity.dart';
import '../entities/city_entity.dart';

abstract class AuthRepository {
  Future<String> login(String correo, String contrasena);
  Future<UserEntity> register({
    required String nombre,
    required String apellido,
    required String correo,
    required String contrasena,
    String? telefono,
    String? rol,
    bool aceptaTratamiento = false,
  });
  Future<UserEntity> me();
  Future<List<CityEntity>> getCities();
  Future<void> deleteAccount();
  Future<UserEntity> updateProfile({
    required String nombre,
    required String apellido,
    required String correo,
    String? telefono,
    String? biografia,
    String? fotoPerfil,
    int? idCiudad,
  });
}
