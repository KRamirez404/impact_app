import '../entities/rating_entity.dart';
import '../repositories/rating_repository.dart';

class RateCampaignUseCase {
  final RatingRepository repository;
  RateCampaignUseCase(this.repository);

  Future<RatingEntity> call({
    required int idCampania,
    required int calificacion,
    String? comentario,
  }) {
    return repository.rateCampaign(
      idCampania: idCampania,
      calificacion: calificacion,
      comentario: comentario,
    );
  }
}

