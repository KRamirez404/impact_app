import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/collection_point_model.dart';

class CollectionPointRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  Map<String, dynamic> _safeMap(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) {
      throw ServerException('Respuesta inválida del servidor');
    }
    return data;
  }

  List<Map<String, dynamic>> _safeList(dynamic data) {
    if (data == null || data is! List) {
      throw ServerException('Respuesta inválida del servidor');
    }
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<CollectionPointModel>> getByCampaign(int idCampaign) async {
    final response = await _dio.get('${ApiConstants.collectionPoints}/campaign/$idCampaign');
    return _safeList(response.data).map((e) => CollectionPointModel.fromJson(e)).toList();
  }

  Future<CollectionPointModel> create(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.collectionPoints, data: payload);
    return CollectionPointModel.fromJson(_safeMap(response.data));
  }
}

