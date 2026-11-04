import 'package:get/get.dart';

import '../../domain/repositories/transfer_repository.dart';
import '../../domain/usecases/create_transfer_usecase.dart';
import '../../domain/usecases/get_bank_account_usecase.dart';
import '../../domain/usecases/get_my_transfers_usecase.dart';
import '../../domain/usecases/get_transfer_usecase.dart';
import '../../domain/usecases/manage_support_transfer_usecase.dart';
import '../../infrastructure/datasources/transfer_remote_datasource.dart';
import '../../infrastructure/repositories/transfer_repository_impl.dart';
import '../controllers/transfer_controller.dart';
import '../controllers/support_transfer_controller.dart';

class TransferBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TransferRemoteDataSource());
    Get.lazyPut<TransferRepository>(
      () => TransferRepositoryImpl(Get.find<TransferRemoteDataSource>()),
    );
    Get.lazyPut(() => GetBankAccountUseCase(Get.find<TransferRepository>()));
    Get.lazyPut(() => CreateTransferUseCase(Get.find<TransferRepository>()));
    Get.lazyPut(() => GetMyTransfersUseCase(Get.find<TransferRepository>()));
    Get.lazyPut(() => GetTransferUseCase(Get.find<TransferRepository>()));
    Get.lazyPut(() => ManageSupportTransferUseCase(Get.find<TransferRepository>()));
    Get.lazyPut(() => SupportTransferController(Get.find<ManageSupportTransferUseCase>()));
    Get.lazyPut(
      () => TransferController(
        repository: Get.find<TransferRepository>(),
        getBankAccount: Get.find<GetBankAccountUseCase>(),
        createTransfer: Get.find<CreateTransferUseCase>(),
        getMyTransfers: Get.find<GetMyTransfersUseCase>(),
        getTransfer: Get.find<GetTransferUseCase>(),
      ),
    );
  }
}
