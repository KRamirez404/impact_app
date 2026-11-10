import '../entities/campaign_entity.dart';
import '../repositories/campaign_repository.dart';

class UpdateCampaignUseCase {
  final CampaignRepository repository;
  UpdateCampaignUseCase(this.repository);

  Future<CampaignEntity> call(int id, Map<String, dynamic> payload) {
    return repository.updateCampaign(id, payload);
  }
}
