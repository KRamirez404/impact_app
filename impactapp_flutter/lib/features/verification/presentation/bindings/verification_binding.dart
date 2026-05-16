import 'package:get/get.dart';
import '../../domain/usecases/upload_support_usecase.dart';
import '../../infrastructure/datasources/verification_remote_datasource.dart';
import '../../infrastructure/repositories/verification_repository_impl.dart';
import '../controllers/verification_controller.dart';

class VerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VerificationRemoteDataSource>(() => VerificationRemoteDataSource());
    Get.lazyPut<VerificationRepositoryImpl>(
      () => VerificationRepositoryImpl(Get.find<VerificationRemoteDataSource>()),
    );
    Get.lazyPut<UploadSupportUseCase>(
      () => UploadSupportUseCase(Get.find<VerificationRepositoryImpl>()),
    );
    Get.lazyPut<VerificationController>(
      () => VerificationController(Get.find<UploadSupportUseCase>()),
      fenix: true,
    );
  }
}

