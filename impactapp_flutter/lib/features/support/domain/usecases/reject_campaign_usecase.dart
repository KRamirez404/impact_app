import '../repositories/support_repository.dart';

class RejectCampaignUseCase {
  final SupportRepository repository;
  RejectCampaignUseCase(this.repository);

  Future<void> call(int campaignId, String note) {
    return repository.reject(campaignId, note);
  }
}
