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

  @override
  Future<List<TransferEntity>> getSupportTransfers() =>
      dataSource.getSupportTransfers();

  @override
  Future<TransferEntity> getSupportTransfer(int transferId) =>
      dataSource.getSupportTransfer(transferId);

  @override
  Future<TransferEntity> claimSupportTransfer(int transferId, String key) =>
      dataSource.claimSupportTransfer(transferId, key);

  @override
  Future<TransferEntity> approveSupportTransfer(
    int transferId,
    Map<String, dynamic> evidence,
    String key,
  ) => dataSource.approveSupportTransfer(transferId, evidence, key);

  @override
  Future<TransferEntity> rejectSupportTransfer(int transferId, String reason, String key) =>
      dataSource.rejectSupportTransfer(transferId, reason, key);

  @override
  Future<Uint8List> downloadSupportReceipt(int transferId) =>
      dataSource.downloadSupportReceipt(transferId);
}
