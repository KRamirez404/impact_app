import '../entities/donor_with_donation_entity.dart';
import '../repositories/campaign_repository.dart';

class GetCampaignDonorsUseCase {
  final CampaignRepository repository;
  GetCampaignDonorsUseCase(this.repository);

  Future<List<DonorWithDonationEntity>> call(int campaignId) {
    return repository.getCampaignDonors(campaignId);
  }
}
