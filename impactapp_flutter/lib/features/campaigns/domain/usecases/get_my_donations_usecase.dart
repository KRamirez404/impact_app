import '../entities/donation_with_campaign_entity.dart';
import '../repositories/campaign_repository.dart';

class GetMyDonationsUseCase {
  final CampaignRepository repository;
  GetMyDonationsUseCase(this.repository);

  Future<List<DonationWithCampaignEntity>> call() {
    return repository.getMyDonations();
  }
}
