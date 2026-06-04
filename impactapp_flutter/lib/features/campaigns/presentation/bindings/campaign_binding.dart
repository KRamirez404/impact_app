import 'package:get/get.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../../domain/usecases/create_campaign_usecase.dart';
import '../../domain/usecases/donate_usecase.dart';
import '../../domain/usecases/get_campaign_detail_usecase.dart';
import '../../domain/usecases/get_campaigns_usecase.dart';
import '../../domain/usecases/get_my_campaigns_usecase.dart';
import '../../domain/usecases/get_my_donations_usecase.dart';
import '../../domain/usecases/toggle_like_usecase.dart';
import '../../infrastructure/datasources/campaign_remote_datasource.dart';
import '../../infrastructure/repositories/campaign_repository_impl.dart';
import '../controllers/campaign_detail_controller.dart';
import '../controllers/campaign_list_controller.dart';

class CampaignBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CampaignRemoteDataSource>(() => CampaignRemoteDataSource());
    Get.lazyPut<CampaignRepository>(
      () => CampaignRepositoryImpl(Get.find<CampaignRemoteDataSource>()),
    );
    Get.lazyPut<GetCampaignsUseCase>(
      () => GetCampaignsUseCase(Get.find<CampaignRepository>()),
    );
    Get.lazyPut<CreateCampaignUseCase>(
      () => CreateCampaignUseCase(Get.find<CampaignRepository>()),
    );
    Get.lazyPut<GetCampaignDetailUseCase>(
      () => GetCampaignDetailUseCase(Get.find<CampaignRepository>()),
    );
    Get.lazyPut<DonateUseCase>(() => DonateUseCase(Get.find<CampaignRepository>()));
    Get.lazyPut<GetMyCampaignsUseCase>(
      () => GetMyCampaignsUseCase(Get.find<CampaignRepository>()),
    );
    Get.lazyPut<GetMyDonationsUseCase>(
      () => GetMyDonationsUseCase(Get.find<CampaignRepository>()),
    );
    Get.lazyPut<ToggleLikeUseCase>(
      () => ToggleLikeUseCase(Get.find<CampaignRepository>()),
    );

    Get.lazyPut<CampaignListController>(
      () => CampaignListController(
        getCampaignsUseCase: Get.find<GetCampaignsUseCase>(),
        createCampaignUseCase: Get.find<CreateCampaignUseCase>(),
      ),
      fenix: true,
    );
    Get.lazyPut<CampaignDetailController>(
      () => CampaignDetailController(
        getCampaignDetailUseCase: Get.find<GetCampaignDetailUseCase>(),
        donateUseCase: Get.find<DonateUseCase>(),
        toggleLikeUseCase: Get.find<ToggleLikeUseCase>(),
      ),
      fenix: true,
    );
  }
}
