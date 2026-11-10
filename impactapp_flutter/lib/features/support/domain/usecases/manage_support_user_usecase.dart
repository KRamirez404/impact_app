import '../repositories/support_repository.dart';

class ManageSupportUserUseCase {
  final SupportRepository repository;
  ManageSupportUserUseCase(this.repository);
  Future<void> block(int id) => repository.blockUser(id);
  Future<void> unblock(int id) => repository.unblockUser(id);
}
