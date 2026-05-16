import 'package:get/get.dart';
import '../../domain/usecases/create_collection_point_usecase.dart';
import '../../domain/usecases/get_collection_points_usecase.dart';
import '../../infrastructure/datasources/collection_point_remote_datasource.dart';
import '../../infrastructure/repositories/collection_point_repository_impl.dart';
import '../controllers/collection_point_controller.dart';

class CollectionPointBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CollectionPointRemoteDataSource>(() => CollectionPointRemoteDataSource());
    Get.lazyPut<CollectionPointRepositoryImpl>(
      () => CollectionPointRepositoryImpl(Get.find<CollectionPointRemoteDataSource>()),
    );
    Get.lazyPut<GetCollectionPointsUseCase>(
      () => GetCollectionPointsUseCase(Get.find<CollectionPointRepositoryImpl>()),
    );
    Get.lazyPut<CreateCollectionPointUseCase>(
      () => CreateCollectionPointUseCase(Get.find<CollectionPointRepositoryImpl>()),
    );
    Get.lazyPut<CollectionPointController>(
      () => CollectionPointController(
        getCollectionPointsUseCase: Get.find<GetCollectionPointsUseCase>(),
        createCollectionPointUseCase: Get.find<CreateCollectionPointUseCase>(),
      ),
      fenix: true,
    );
  }
}

