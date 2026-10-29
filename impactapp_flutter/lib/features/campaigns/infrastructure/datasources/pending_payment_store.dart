import 'package:get_storage/get_storage.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../domain/entities/pending_payment_session.dart';

class PendingPaymentStore {
  final GetStorage storage;

  PendingPaymentStore({GetStorage? storage})
    : storage = storage ?? GetStorage();

  PendingPaymentSession? read() {
    final value = storage.read<dynamic>(StorageKeys.pendingWompiPayment);
    if (value is! Map) return null;
    try {
      return PendingPaymentSession.fromMap(Map<String, dynamic>.from(value));
    } on FormatException {
      storage.remove(StorageKeys.pendingWompiPayment);
      return null;
    }
  }

  Future<void> save(PendingPaymentSession session) =>
      storage.write(StorageKeys.pendingWompiPayment, session.toMap());

  Future<void> clear() => storage.remove(StorageKeys.pendingWompiPayment);
}
