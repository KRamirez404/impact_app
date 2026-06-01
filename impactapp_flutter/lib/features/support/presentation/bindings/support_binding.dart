import 'package:get/get.dart';

import '../../../campaigns/domain/usecases/get_campaigns_usecase.dart';
import '../../../campaigns/domain/usecases/get_campaign_detail_usecase.dart';
import '../controllers/support_controller.dart';

class SupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupportController>(
      () => SupportController(Get.find<GetCampaignsUseCase>(), Get.find<GetCampaignDetailUseCase>()),
      fenix: true,
    );
  }
}
