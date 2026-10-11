import '../entities/city_entity.dart';
import '../repositories/auth_repository.dart';

class GetProfileCitiesUseCase {
  final AuthRepository repository;

  GetProfileCitiesUseCase(this.repository);

  Future<List<CityEntity>> call() => repository.getCities();
}
