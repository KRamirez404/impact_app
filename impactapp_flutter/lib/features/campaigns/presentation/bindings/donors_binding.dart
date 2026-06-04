import 'package:get/get.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../../domain/usecases/get_campaign_donors_usecase.dart';
import '../../infrastructure/datasources/campaign_remote_datasource.dart';
import '../../infrastructure/repositories/campaign_repository_impl.dart';
import '../controllers/donors_controller.dart';

class DonorsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CampaignRemoteDataSource>(() => CampaignRemoteDataSource());
    Get.lazyPut<CampaignRepository>(
      () => CampaignRepositoryImpl(Get.find<CampaignRemoteDataSource>()),
    );
    Get.lazyPut<GetCampaignDonorsUseCase>(
      () => GetCampaignDonorsUseCase(Get.find<CampaignRepository>()),
    );
    Get.lazyPut<DonorsController>(
      () => DonorsController(
        getCampaignDonorsUseCase: Get.find<GetCampaignDonorsUseCase>(),
      ),
      fenix: true,
    );
  }
}
