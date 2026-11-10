import '../repositories/campaign_repository.dart';

class UploadFinancialReportUseCase {
  final CampaignRepository repository;

  UploadFinancialReportUseCase(this.repository);

  Future<Map<String, dynamic>> call(
    int campaignId,
    String filePath,
    String fileName,
  ) {
    return repository.uploadFinancialReport(campaignId, filePath, fileName);
  }
}
