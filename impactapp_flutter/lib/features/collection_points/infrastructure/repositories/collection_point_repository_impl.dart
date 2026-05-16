import '../../domain/entities/collection_point_entity.dart';
import '../../domain/repositories/collection_point_repository.dart';
import '../datasources/collection_point_remote_datasource.dart';

class CollectionPointRepositoryImpl implements CollectionPointRepository {
  final CollectionPointRemoteDataSource dataSource;
  CollectionPointRepositoryImpl(this.dataSource);

  @override
  Future<CollectionPointEntity> create(Map<String, dynamic> payload) => dataSource.create(payload);

  @override
  Future<List<CollectionPointEntity>> getByCampaign(int idCampaign) => dataSource.getByCampaign(idCampaign);
}

