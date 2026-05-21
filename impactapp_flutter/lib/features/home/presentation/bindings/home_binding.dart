import 'package:get/get.dart';
import '../../../campaigns/domain/usecases/get_top_donors_usecase.dart';
import '../../../campaigns/infrastructure/repositories/campaign_repository_impl.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GetTopDonorsUseCase>(
      () => GetTopDonorsUseCase(Get.find<CampaignRepositoryImpl>()),
    );
    Get.lazyPut<HomeController>(
      () => HomeController(getTopDonorsUseCase: Get.find<GetTopDonorsUseCase>()),
      fenix: true,
    );
  }
}
