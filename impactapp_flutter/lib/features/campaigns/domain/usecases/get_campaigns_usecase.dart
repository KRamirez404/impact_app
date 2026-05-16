import '../entities/campaign_entity.dart';
import '../repositories/campaign_repository.dart';

class GetCampaignsUseCase {
  final CampaignRepository repository;
  GetCampaignsUseCase(this.repository);

  Future<List<CampaignEntity>> call({
    int? ciudad,
    int? categoria,
    String? tipoAyuda,
    String? estado,
  }) {
    return repository.getCampaigns(
      ciudad: ciudad,
      categoria: categoria,
      tipoAyuda: tipoAyuda,
      estado: estado,
    );
  }
}

