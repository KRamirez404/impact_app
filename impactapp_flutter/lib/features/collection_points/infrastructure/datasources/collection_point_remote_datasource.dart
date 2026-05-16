import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/collection_point_model.dart';

class CollectionPointRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  Future<List<CollectionPointModel>> getByCampaign(int idCampaign) async {
    final response = await _dio.get('${ApiConstants.collectionPoints}/campaign/$idCampaign');
    return (response.data as List).map((e) => CollectionPointModel.fromJson(e)).toList();
  }

  Future<CollectionPointModel> create(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.collectionPoints, data: payload);
    return CollectionPointModel.fromJson(response.data as Map<String, dynamic>);
  }
}

