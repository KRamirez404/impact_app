import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../../core/utils/cop_amount.dart';
import '../../domain/entities/bank_account_entity.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../../domain/usecases/create_transfer_usecase.dart';
import '../../domain/usecases/get_bank_account_usecase.dart';
import '../../domain/usecases/get_my_transfers_usecase.dart';
import '../../domain/usecases/get_transfer_usecase.dart';
import 'transfer_error_mapper.dart';

class TransferController extends GetxController {
  final TransferRepository repository;
  final GetBankAccountUseCase getBankAccount;
  final CreateTransferUseCase createTransfer;
  final GetMyTransfersUseCase getMyTransfers;
  final GetTransferUseCase getTransfer;

  TransferController({
    required this.repository,
    required this.getBankAccount,
    required this.createTransfer,
    required this.getMyTransfers,
    required this.getTransfer,
  });

  final account = Rxn<BankAccountEntity>();
  final current = Rxn<TransferEntity>();
  final transfers = <TransferEntity>[].obs;
  final loading = false.obs;
  final error = ''.obs;
  String? _createKey;

  Future<void> loadAccount(int campaignId) async {
    await _run(
      () async => account.value = await getBankAccount(campaignId),
      loadingAccount: true,
    );
  }

  Future<void> loadMine() async {
    await _run(() async => transfers.assignAll(await getMyTransfers()));
  }

  Future<void> loadTransfer(int transferId) async {
    await _run(() async => current.value = await getTransfer(transferId));
  }

  Future<TransferEntity?> register(Map<String, dynamic> payload) async {
    _createKey ??= newIdempotencyKey();
    TransferEntity? result;
    await _run(() async {
      result = await createTransfer(payload, _createKey!);
      current.value = result;
    });
    if (result != null) _createKey = null;
    return result;
  }

  Future<bool> upload(String filePath, {required bool resubmit}) async {
    final transfer = current.value;
    if (transfer == null) return false;
    var success = false;
    await _run(() async {
      current.value = await repository.uploadReceipt(
        transfer.idTransferencia,
        filePath,
        resubmit: resubmit,
      );
      success = true;
    });
    return success;
  }

  Future<Uint8List?> download() async {
    final transfer = current.value;
    if (transfer == null) return null;
    Uint8List? bytes;
    await _run(() async {
      bytes = await repository.downloadReceipt(transfer.idTransferencia);
    });
    return bytes;
  }

  Future<void> _run(
    Future<void> Function() operation, {
    bool loadingAccount = false,
  }) async {
    try {
      loading.value = true;
      error.value = '';
      await operation();
    } catch (exception) {
      error.value = transferFriendlyError(
        exception,
        loadingAccount: loadingAccount,
      );
    } finally {
      loading.value = false;
    }
  }
}
