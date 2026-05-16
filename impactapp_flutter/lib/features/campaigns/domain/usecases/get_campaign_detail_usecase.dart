import '../entities/campaign_entity.dart';
import '../repositories/campaign_repository.dart';

class GetCampaignDetailUseCase {
  final CampaignRepository repository;
  GetCampaignDetailUseCase(this.repository);

  Future<CampaignEntity> call(int id) {
    return repository.getCampaignDetail(id);
  }
}

