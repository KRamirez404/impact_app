import '../entities/transfer_entity.dart';
import '../repositories/transfer_repository.dart';

class CreateTransferUseCase {
  final TransferRepository repository;
  const CreateTransferUseCase(this.repository);
  Future<TransferEntity> call(
    Map<String, dynamic> payload,
    String idempotencyKey,
  ) => repository.createTransfer(payload, idempotencyKey);
}
