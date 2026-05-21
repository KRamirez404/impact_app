import '../../domain/entities/campaign_entity.dart';
import '../../domain/entities/donation_entity.dart';
import '../../domain/entities/donation_with_campaign_entity.dart';
import '../../domain/entities/donor_with_donation_entity.dart';
import '../../domain/entities/like_status_entity.dart';
import '../../domain/entities/top_donor_entity.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../datasources/campaign_remote_datasource.dart';

class CampaignRepositoryImpl implements CampaignRepository {
  final CampaignRemoteDataSource dataSource;
  CampaignRepositoryImpl(this.dataSource);

  @override
  Future<CampaignEntity> createCampaign(Map<String, dynamic> payload) {
    return dataSource.createCampaign(payload);
  }

  @override
  Future<DonationEntity> donate(Map<String, dynamic> payload) {
    return dataSource.donate(payload);
  }

  @override
  Future<List<DonationWithCampaignEntity>> getMyDonations() {
    return dataSource.getMyDonations();
  }

  @override
  Future<LikeStatusEntity> toggleLike(int campaignId) {
    return dataSource.toggleLike(campaignId);
  }

  @override
  Future<List<TopDonorEntity>> getTopDonors({int limit = 5}) {
    return dataSource.getTopDonors(limit: limit);
  }

  @override
  Future<CampaignEntity> getCampaignDetail(int id) {
    return dataSource.getCampaignDetail(id);
  }

  @override
  Future<List<CampaignEntity>> getCampaigns({
    int? ciudad,
    int? categoria,
    String? tipoAyuda,
    String? estado,
  }) {
    return dataSource.getCampaigns(
      ciudad: ciudad,
      categoria: categoria,
      tipoAyuda: tipoAyuda,
      estado: estado,
    );
  }

  @override
  Future<List<CampaignEntity>> getMyCampaigns() {
    return dataSource.getMyCampaigns();
  }

  @override
  Future<List<DonorWithDonationEntity>> getCampaignDonors(int campaignId) {
    return dataSource.getCampaignDonors(campaignId);
  }
}
