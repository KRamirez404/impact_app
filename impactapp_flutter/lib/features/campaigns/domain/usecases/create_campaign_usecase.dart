import '../entities/campaign_entity.dart';
import '../repositories/campaign_repository.dart';

class CreateCampaignUseCase {
  final CampaignRepository repository;
  CreateCampaignUseCase(this.repository);

  Future<CampaignEntity> call(Map<String, dynamic> payload) {
    return repository.createCampaign(payload);
  }
}

