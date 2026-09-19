import '../repositories/support_repository.dart';

class InvalidateCampaignUseCase {
  final SupportRepository repository;
  InvalidateCampaignUseCase(this.repository);

  Future<void> call(int campaignId, String motivo) {
    return repository.invalidate(campaignId, motivo);
  }
}
