import '../entities/donation_entity.dart';
import '../repositories/campaign_repository.dart';

class DonateUseCase {
  final CampaignRepository repository;
  DonateUseCase(this.repository);

  Future<DonationEntity> call(Map<String, dynamic> payload) {
    return repository.donate(payload);
  }
}

