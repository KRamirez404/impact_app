import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  Future<UserEntity> call({
    required String nombre,
    required String apellido,
    required String correo,
    required String contrasena,
    String? telefono,
  }) {
    return repository.register(
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      contrasena: contrasena,
      telefono: telefono,
    );
  }
}

