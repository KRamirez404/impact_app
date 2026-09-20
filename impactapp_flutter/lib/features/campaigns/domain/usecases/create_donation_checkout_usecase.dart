import '../entities/donation_checkout_entity.dart';
import '../repositories/campaign_repository.dart';

class CreateDonationCheckoutUseCase {
  final CampaignRepository repository;
  CreateDonationCheckoutUseCase(this.repository);

  Future<DonationCheckoutEntity> call(Map<String, dynamic> payload) {
    return repository.createDonationCheckout(payload);
  }
}
