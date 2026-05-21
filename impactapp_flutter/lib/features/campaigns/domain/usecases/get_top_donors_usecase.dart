import '../entities/top_donor_entity.dart';
import '../repositories/campaign_repository.dart';

class GetTopDonorsUseCase {
  final CampaignRepository repository;
  GetTopDonorsUseCase(this.repository);

  Future<List<TopDonorEntity>> call({int limit = 5}) {
    return repository.getTopDonors(limit: limit);
  }
}
