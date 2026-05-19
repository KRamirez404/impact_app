import '../entities/campaign_entity.dart';
import '../entities/donation_entity.dart';
import '../entities/donation_with_campaign_entity.dart';

abstract class CampaignRepository {
  Future<List<CampaignEntity>> getCampaigns({
    int? ciudad,
    int? categoria,
    String? tipoAyuda,
    String? estado,
  });
  Future<List<CampaignEntity>> getMyCampaigns();
  Future<CampaignEntity> getCampaignDetail(int id);
  Future<CampaignEntity> createCampaign(Map<String, dynamic> payload);
  Future<DonationEntity> donate(Map<String, dynamic> payload);
  Future<List<DonationWithCampaignEntity>> getMyDonations();
}
