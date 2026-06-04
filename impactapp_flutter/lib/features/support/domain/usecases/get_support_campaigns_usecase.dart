import '../../../campaigns/domain/entities/campaign_entity.dart';
import '../repositories/support_repository.dart';

class GetSupportCampaignsUseCase {
  final SupportRepository repository;
  GetSupportCampaignsUseCase(this.repository);

  Future<List<CampaignEntity>> call() {
    return repository.getCampaigns();
  }
}
