import '../entities/like_status_entity.dart';
import '../repositories/campaign_repository.dart';

class ToggleLikeUseCase {
  final CampaignRepository repository;
  ToggleLikeUseCase(this.repository);

  Future<LikeStatusEntity> call(int campaignId) {
    return repository.toggleLike(campaignId);
  }
}
