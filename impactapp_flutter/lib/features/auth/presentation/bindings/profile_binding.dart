import 'package:get/get.dart';
import '../../../campaigns/domain/usecases/get_my_campaigns_usecase.dart';
import '../../../campaigns/domain/usecases/get_my_donations_usecase.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        getMyCampaignsUseCase: Get.find<GetMyCampaignsUseCase>(),
        getMyDonationsUseCase: Get.find<GetMyDonationsUseCase>(),
      ),
      fenix: true,
    );
  }
}
