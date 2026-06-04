import 'package:get/get.dart';
import '../../domain/repositories/rating_repository.dart';
import '../../domain/usecases/rate_campaign_usecase.dart';
import '../../infrastructure/datasources/rating_remote_datasource.dart';
import '../../infrastructure/repositories/rating_repository_impl.dart';
import '../controllers/rating_controller.dart';

class RatingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RatingRemoteDataSource>(() => RatingRemoteDataSource());
    Get.lazyPut<RatingRepository>(
      () => RatingRepositoryImpl(Get.find<RatingRemoteDataSource>()),
    );
    Get.lazyPut<RateCampaignUseCase>(
      () => RateCampaignUseCase(Get.find<RatingRepository>()),
    );
    Get.lazyPut<RatingController>(
      () => RatingController(Get.find<RateCampaignUseCase>()),
      fenix: true,
    );
  }
}

