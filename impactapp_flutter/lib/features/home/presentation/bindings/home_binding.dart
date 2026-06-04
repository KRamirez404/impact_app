import 'package:get/get.dart';
import '../../../campaigns/domain/repositories/campaign_repository.dart';
import '../../../campaigns/domain/usecases/get_top_donors_usecase.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GetTopDonorsUseCase>(
      () => GetTopDonorsUseCase(Get.find<CampaignRepository>()),
    );
    Get.lazyPut<HomeController>(
      () => HomeController(getTopDonorsUseCase: Get.find<GetTopDonorsUseCase>()),
      fenix: true,
    );
  }
}
