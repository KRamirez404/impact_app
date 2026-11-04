import 'dart:typed_data';

import '../entities/transfer_entity.dart';
import '../repositories/transfer_repository.dart';

class ManageSupportTransferUseCase {
  final TransferRepository repository;
  const ManageSupportTransferUseCase(this.repository);

  Future<List<TransferEntity>> list() => repository.getSupportTransfers();
  Future<TransferEntity> detail(int id) => repository.getSupportTransfer(id);
  Future<TransferEntity> claim(int id, String key) =>
      repository.claimSupportTransfer(id, key);
  Future<TransferEntity> approve(
    int id,
    Map<String, dynamic> evidence,
    String key,
  ) => repository.approveSupportTransfer(id, evidence, key);
  Future<TransferEntity> reject(int id, String reason, String key) =>
      repository.rejectSupportTransfer(id, reason, key);
  Future<Uint8List> receipt(int id) => repository.downloadSupportReceipt(id);
}
