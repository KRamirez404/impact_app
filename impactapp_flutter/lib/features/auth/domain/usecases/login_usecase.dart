import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<String> call(String correo, String contrasena) {
    return repository.login(correo, contrasena);
  }
}

