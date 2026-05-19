import '../entities/campaign_entity.dart';
import '../repositories/campaign_repository.dart';

class GetMyCampaignsUseCase {
  final CampaignRepository repository;
  GetMyCampaignsUseCase(this.repository);

  Future<List<CampaignEntity>> call() {
    return repository.getMyCampaigns();
  }
}
