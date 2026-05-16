import '../entities/collection_point_entity.dart';

abstract class CollectionPointRepository {
  Future<List<CollectionPointEntity>> getByCampaign(int idCampaign);
  Future<CollectionPointEntity> create(Map<String, dynamic> payload);
}

