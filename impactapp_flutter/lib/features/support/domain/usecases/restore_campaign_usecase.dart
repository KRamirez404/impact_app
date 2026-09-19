import '../repositories/support_repository.dart';

class RestoreCampaignUseCase {
  final SupportRepository repository;
  RestoreCampaignUseCase(this.repository);

  Future<void> call(int campaignId) {
    return repository.restore(campaignId);
  }
}
