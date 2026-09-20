import '../entities/donation_entity.dart';
import '../repositories/campaign_repository.dart';

class GetDonationStatusUseCase {
  final CampaignRepository repository;
  GetDonationStatusUseCase(this.repository);

  Future<DonationEntity> call(int donationId) {
    return repository.getDonationStatus(donationId);
  }
}
