import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../infrastructure/datasources/auth_remote_datasource.dart';
import '../../infrastructure/repositories/auth_repository_impl.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRemoteDataSource>(() => AuthRemoteDataSource());
    Get.lazyPut<AuthRepositoryImpl>(
      () => AuthRepositoryImpl(
        dataSource: Get.find<AuthRemoteDataSource>(),
        storage: GetStorage(),
      ),
    );
    Get.lazyPut<LoginUseCase>(() => LoginUseCase(Get.find<AuthRepositoryImpl>()));
    Get.lazyPut<RegisterUseCase>(
      () => RegisterUseCase(Get.find<AuthRepositoryImpl>()),
    );
    Get.lazyPut<AuthController>(
      () => AuthController(
        loginUseCase: Get.find<LoginUseCase>(),
        registerUseCase: Get.find<RegisterUseCase>(),
        repository: Get.find<AuthRepositoryImpl>(),
        storage: GetStorage(),
      ),
      fenix: true,
    );
  }
}

