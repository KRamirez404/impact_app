import 'dart:typed_data';

import '../entities/bank_account_entity.dart';
import '../entities/transfer_entity.dart';

abstract class TransferRepository {
  Future<BankAccountEntity> getBankAccount(int campaignId);
  Future<TransferEntity> createTransfer(
    Map<String, dynamic> payload,
    String idempotencyKey,
  );
  Future<List<TransferEntity>> getMyTransfers();
  Future<TransferEntity> getTransfer(int transferId);
  Future<TransferEntity> uploadReceipt(
    int transferId,
    String filePath, {
    required bool resubmit,
  });
  Future<Uint8List> downloadReceipt(int transferId);
  Future<List<TransferEntity>> getSupportTransfers();
  Future<TransferEntity> getSupportTransfer(int transferId);
  Future<TransferEntity> claimSupportTransfer(int transferId, String key);
  Future<TransferEntity> approveSupportTransfer(
    int transferId,
    Map<String, dynamic> evidence,
    String key,
  );
  Future<TransferEntity> rejectSupportTransfer(int transferId, String reason, String key);
  Future<Uint8List> downloadSupportReceipt(int transferId);
}
