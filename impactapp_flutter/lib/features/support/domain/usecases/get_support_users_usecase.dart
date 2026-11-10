import '../entities/support_user_entity.dart';
import '../repositories/support_repository.dart';

class GetSupportUsersUseCase {
  final SupportRepository repository;
  GetSupportUsersUseCase(this.repository);
  Future<List<SupportUserEntity>> call() => repository.getUsers();
}
