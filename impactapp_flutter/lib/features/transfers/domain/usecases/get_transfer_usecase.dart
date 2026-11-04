import '../entities/transfer_entity.dart';
import '../repositories/transfer_repository.dart';

class GetTransferUseCase {
  final TransferRepository repository;
  const GetTransferUseCase(this.repository);
  Future<TransferEntity> call(int transferId) =>
      repository.getTransfer(transferId);
}
