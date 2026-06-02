import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;
  final GetStorage storage;

  AuthRepositoryImpl({
    required this.dataSource,
    required this.storage,
  });

  @override
  Future<String> login(String correo, String contrasena) async {
    final (token, user) = await dataSource.login(correo, contrasena);
    await storage.write(StorageKeys.token, token);
    await storage.write(StorageKeys.user, jsonEncode(user.toJson()));
    return token;
  }

  @override
  Future<UserEntity> register({
    required String nombre,
    required String apellido,
    required String correo,
    required String contrasena,
    String? telefono,
  }) async {
    return dataSource.register(
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      contrasena: contrasena,
      telefono: telefono,
    );
  }

  @override
  Future<UserEntity> me() async {
    final user = await dataSource.me();
    await storage.write(StorageKeys.user, jsonEncode(user.toJson()));
    return user;
  }

  @override
  Future<UserEntity> updateProfile({
    required String nombre,
    required String apellido,
    required String correo,
    String? telefono,
    String? biografia,
    String? fotoPerfil,
  }) async {
    final user = await dataSource.updateProfile(
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      telefono: telefono,
      biografia: biografia,
      fotoPerfil: fotoPerfil,
    );
    await storage.write(StorageKeys.user, jsonEncode(user.toJson()));
    return user;
  }
}
