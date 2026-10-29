import 'dart:typed_data';

import '../../domain/entities/bank_account_entity.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../datasources/transfer_remote_datasource.dart';

class TransferRepositoryImpl implements TransferRepository {
  final TransferRemoteDataSource dataSource;
  const TransferRepositoryImpl(this.dataSource);

  @override
  Future<BankAccountEntity> getBankAccount(int campaignId) =>
      dataSource.getBankAccount(campaignId);

  @override
  Future<TransferEntity> createTransfer(
    Map<String, dynamic> payload,
    String idempotencyKey,
  ) => dataSource.createTransfer(payload, idempotencyKey);

  @override
  Future<List<TransferEntity>> getMyTransfers() => dataSource.getMyTransfers();

  @override
  Future<TransferEntity> getTransfer(int transferId) =>
      dataSource.getTransfer(transferId);

  @override
  Future<TransferEntity> uploadReceipt(
    int transferId,
    String filePath, {
    required bool resubmit,
  }) => dataSource.uploadReceipt(transferId, filePath, resubmit: resubmit);

  @override
  Future<Uint8List> downloadReceipt(int transferId) =>
      dataSource.downloadReceipt(transferId);
}
