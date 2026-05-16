import '../entities/rating_entity.dart';

abstract class RatingRepository {
  Future<RatingEntity> rateCampaign({
    required int idCampania,
    required int calificacion,
    String? comentario,
  });
}

