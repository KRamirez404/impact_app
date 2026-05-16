import '../entities/collection_point_entity.dart';
import '../repositories/collection_point_repository.dart';

class CreateCollectionPointUseCase {
  final CollectionPointRepository repository;
  CreateCollectionPointUseCase(this.repository);

  Future<CollectionPointEntity> call(Map<String, dynamic> payload) {
    return repository.create(payload);
  }
}

