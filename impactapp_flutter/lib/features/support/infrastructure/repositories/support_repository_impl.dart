import '../../../campaigns/domain/entities/campaign_entity.dart';
import '../../domain/entities/support_summary_entity.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_remote_datasource.dart';

class SupportRepositoryImpl implements SupportRepository {
  final SupportRemoteDataSource dataSource;
  SupportRepositoryImpl(this.dataSource);

  @override
  Future<SupportSummaryEntity> getSummary() {
    return dataSource.getSummary();
  }

  @override
  Future<List<CampaignEntity>> getCampaigns() {
    return dataSource.getCampaigns();
  }

  @override
  Future<void> approve(int campaignId) {
    return dataSource.approve(campaignId);
  }

  @override
  Future<void> reject(int campaignId, String note) {
    return dataSource.reject(campaignId, note);
  }

  @override
  Future<void> invalidate(int campaignId, String motivo) {
    return dataSource.invalidate(campaignId, motivo);
  }

  @override
  Future<void> delete(int campaignId, String motivo) {
    return dataSource.delete(campaignId, motivo);
  }

  @override
  Future<void> restore(int campaignId) {
    return dataSource.restore(campaignId);
  }
}
