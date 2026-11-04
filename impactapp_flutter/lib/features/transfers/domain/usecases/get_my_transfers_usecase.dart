import '../entities/transfer_entity.dart';
import '../repositories/transfer_repository.dart';

class GetMyTransfersUseCase {
  final TransferRepository repository;
  const GetMyTransfersUseCase(this.repository);
  Future<List<TransferEntity>> call() => repository.getMyTransfers();
}
