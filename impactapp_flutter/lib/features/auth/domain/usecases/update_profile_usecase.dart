import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository repository;
  UpdateProfileUseCase(this.repository);

  Future<UserEntity> call({
    required String nombre,
    required String apellido,
    required String correo,
    String? telefono,
    String? biografia,
  }) {
    return repository.updateProfile(
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      telefono: telefono,
      biografia: biografia,
    );
  }
}
