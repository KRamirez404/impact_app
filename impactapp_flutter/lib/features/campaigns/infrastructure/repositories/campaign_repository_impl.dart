import '../../domain/entities/campaign_entity.dart';
import '../../domain/entities/donation_entity.dart';
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
}

