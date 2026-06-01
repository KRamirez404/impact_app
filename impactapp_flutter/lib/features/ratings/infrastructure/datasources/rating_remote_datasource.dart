import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/rating_model.dart';

class RatingRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  Map<String, dynamic> _safeMap(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) {
      throw ServerException('Respuesta inválida del servidor');
    }
    return data;
  }

  Future<RatingModel> rateCampaign({
    required int idCampania,
    required int calificacion,
    String? comentario,
  }) async {
    final response = await _dio.post(
      ApiConstants.ratings,
      data: {
        'id_campania': idCampania,
        'calificacion': calificacion,
        'comentario': comentario,
      },
    );
    return RatingModel.fromJson(_safeMap(response.data));
  }
}

