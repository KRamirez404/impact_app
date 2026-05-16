import '../entities/collection_point_entity.dart';
import '../repositories/collection_point_repository.dart';

class GetCollectionPointsUseCase {
  final CollectionPointRepository repository;
  GetCollectionPointsUseCase(this.repository);

  Future<List<CollectionPointEntity>> call(int idCampaign) {
    return repository.getByCampaign(idCampaign);
  }
}

