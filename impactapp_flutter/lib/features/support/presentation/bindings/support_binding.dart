import 'package:get/get.dart';
import '../../../campaigns/domain/usecases/get_campaign_detail_usecase.dart';
import '../../domain/repositories/support_repository.dart';
import '../../domain/usecases/approve_campaign_usecase.dart';
import '../../domain/usecases/reject_campaign_usecase.dart';
import '../../domain/usecases/invalidate_campaign_usecase.dart';
import '../../domain/usecases/delete_campaign_usecase.dart';
import '../../domain/usecases/restore_campaign_usecase.dart';
import '../../domain/usecases/get_support_summary_usecase.dart';
import '../../domain/usecases/get_support_campaigns_usecase.dart';
import '../../infrastructure/datasources/support_remote_datasource.dart';
import '../../infrastructure/repositories/support_repository_impl.dart';
import '../controllers/support_controller.dart';

class SupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupportRemoteDataSource>(() => SupportRemoteDataSource());
    Get.lazyPut<SupportRepository>(
      () => SupportRepositoryImpl(Get.find<SupportRemoteDataSource>()),
    );
    Get.lazyPut<GetSupportCampaignsUseCase>(
      () => GetSupportCampaignsUseCase(Get.find<SupportRepository>()),
    );
    Get.lazyPut<GetSupportSummaryUseCase>(
      () => GetSupportSummaryUseCase(Get.find<SupportRepository>()),
    );
    Get.lazyPut<ApproveCampaignUseCase>(
      () => ApproveCampaignUseCase(Get.find<SupportRepository>()),
    );
    Get.lazyPut<RejectCampaignUseCase>(
      () => RejectCampaignUseCase(Get.find<SupportRepository>()),
    );
    Get.lazyPut<InvalidateCampaignUseCase>(
      () => InvalidateCampaignUseCase(Get.find<SupportRepository>()),
    );
    Get.lazyPut<DeleteCampaignUseCase>(
      () => DeleteCampaignUseCase(Get.find<SupportRepository>()),
    );
    Get.lazyPut<RestoreCampaignUseCase>(
      () => RestoreCampaignUseCase(Get.find<SupportRepository>()),
    );
    Get.lazyPut<SupportController>(
      () => SupportController(
        Get.find<GetCampaignDetailUseCase>(),
        Get.find<GetSupportCampaignsUseCase>(),
        Get.find<GetSupportSummaryUseCase>(),
        Get.find<ApproveCampaignUseCase>(),
        Get.find<RejectCampaignUseCase>(),
        Get.find<InvalidateCampaignUseCase>(),
        Get.find<DeleteCampaignUseCase>(),
        Get.find<RestoreCampaignUseCase>(),
      ),
      fenix: true,
    );
  }
}
