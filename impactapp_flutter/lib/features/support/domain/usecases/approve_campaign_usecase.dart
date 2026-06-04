import '../repositories/support_repository.dart';

class ApproveCampaignUseCase {
  final SupportRepository repository;
  ApproveCampaignUseCase(this.repository);

  Future<void> call(int campaignId) {
    return repository.approve(campaignId);
  }
}
