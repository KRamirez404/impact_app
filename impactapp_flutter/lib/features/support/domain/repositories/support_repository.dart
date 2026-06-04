import '../../../campaigns/domain/entities/campaign_entity.dart';
import '../entities/support_summary_entity.dart';

abstract class SupportRepository {
  Future<SupportSummaryEntity> getSummary();
  Future<List<CampaignEntity>> getCampaigns();
  Future<void> approve(int campaignId);
  Future<void> reject(int campaignId, String note);
}
