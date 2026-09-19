import '../repositories/support_repository.dart';

class DeleteCampaignUseCase {
  final SupportRepository repository;
  DeleteCampaignUseCase(this.repository);

  Future<void> call(int campaignId, String motivo) {
    return repository.delete(campaignId, motivo);
  }
}
