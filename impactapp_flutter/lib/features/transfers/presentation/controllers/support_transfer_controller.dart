import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../../core/utils/cop_amount.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/usecases/manage_support_transfer_usecase.dart';
import 'transfer_error_mapper.dart';

class SupportTransferController extends GetxController {
  final ManageSupportTransferUseCase manage;
  SupportTransferController(this.manage);

  final transfers = <TransferEntity>[].obs;
  final current = Rxn<TransferEntity>();
  final loading = false.obs;
  final error = ''.obs;
  String? _approvalKey;
  String? _approvalData;

  Future<void> load() async {
    await _run(() async => transfers.assignAll(await manage.list()));
  }

  Future<void> detail(int id) async {
    current.value = null;
    await _run(() async => current.value = await manage.detail(id));
  }

  Future<bool> claim(int id) =>
      _change(() => manage.claim(id, newIdempotencyKey()));

  Future<bool> approve(int id, Map<String, dynamic> evidence) async {
    final data = '$id:$evidence';
    if (_approvalData != data) {
      _approvalData = data;
      _approvalKey = newIdempotencyKey();
    }
    final result = await _change(
      () => manage.approve(id, evidence, _approvalKey!),
    );
    if (result) {
      _approvalData = null;
      _approvalKey = null;
    }
    return result;
  }

  Future<bool> reject(int id, String reason) =>
      _change(() => manage.reject(id, reason, newIdempotencyKey()));

  Future<Uint8List?> receipt(int id) async {
    Uint8List? data;
    await _run(() async => data = await manage.receipt(id));
    return data;
  }

  Future<bool> _change(Future<TransferEntity> Function() action) async {
    var succeeded = false;
    await _run(() async {
      current.value = await action();
      succeeded = true;
    });
    if (succeeded) await load();
    return succeeded;
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      loading.value = true;
      error.value = '';
      await action();
    } catch (exception) {
      error.value = transferFriendlyError(exception);
    } finally {
      loading.value = false;
    }
  }
}
