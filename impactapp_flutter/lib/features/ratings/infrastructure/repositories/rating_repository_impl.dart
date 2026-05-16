import '../../domain/entities/rating_entity.dart';
import '../../domain/repositories/rating_repository.dart';
import '../datasources/rating_remote_datasource.dart';

class RatingRepositoryImpl implements RatingRepository {
  final RatingRemoteDataSource dataSource;
  RatingRepositoryImpl(this.dataSource);

  @override
  Future<RatingEntity> rateCampaign({
    required int idCampania,
    required int calificacion,
    String? comentario,
  }) {
    return dataSource.rateCampaign(
      idCampania: idCampania,
      calificacion: calificacion,
      comentario: comentario,
    );
  }
}

