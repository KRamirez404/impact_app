import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/campaign_model.dart';
import '../models/donation_model.dart';
import '../models/donation_with_campaign_model.dart';
import '../models/donor_with_donation_model.dart';
import '../models/like_status_model.dart';
import '../models/top_donor_model.dart';

class CampaignRemoteDataSource {
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

  Future<List<Map<String, dynamic>>> getCities() async {
    final response = await _dio.get(ApiConstants.cities);
    return _safeList(response.data);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _dio.get(ApiConstants.categories);
    return _safeList(response.data);
  }

  Future<List<CampaignModel>> getCampaigns({
    int? ciudad,
    int? categoria,
    String? tipoAyuda,
    String? estado,
  }) async {
    final query = <String, dynamic>{};
    if (ciudad != null) query['ciudad'] = ciudad;
    if (categoria != null) query['categoria'] = categoria;
    if (tipoAyuda != null && tipoAyuda.isNotEmpty) query['tipo_ayuda'] = tipoAyuda;
    if (estado != null && estado.isNotEmpty) query['estado'] = estado;

    final response = await _dio.get(ApiConstants.campaigns, queryParameters: query);
    return _safeList(response.data).map((e) => CampaignModel.fromJson(e)).toList();
  }

  Future<List<CampaignModel>> getMyCampaigns() async {
    final response = await _dio.get(ApiConstants.myCampaigns);
    return _safeList(response.data).map((e) => CampaignModel.fromJson(e)).toList();
  }

  Future<CampaignModel> getCampaignDetail(int id) async {
    final response = await _dio.get('${ApiConstants.campaigns}/$id');
    return CampaignModel.fromJson(_safeMap(response.data));
  }

  Future<CampaignModel> createCampaign(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.campaigns, data: payload);
    return CampaignModel.fromJson(_safeMap(response.data));
  }

  Future<DonationModel> donate(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.donations, data: payload);
    return DonationModel.fromJson(_safeMap(response.data));
  }

  Future<List<DonationWithCampaignModel>> getMyDonations() async {
    final response = await _dio.get(ApiConstants.myDonations);
    return _safeList(response.data).map((e) => DonationWithCampaignModel.fromJson(e)).toList();
  }

  Future<LikeStatusModel> toggleLike(int campaignId) async {
    final response = await _dio.post(
      '${ApiConstants.likes}/toggle',
      data: {'id_campania': campaignId},
    );
    return LikeStatusModel.fromJson(_safeMap(response.data));
  }

  Future<List<TopDonorModel>> getTopDonors({int limit = 5}) async {
    final response = await _dio.get(
      ApiConstants.topDonors,
      queryParameters: {'limit': limit},
    );
    return _safeList(response.data).map((e) => TopDonorModel.fromJson(e)).toList();
  }

  Future<List<DonorWithDonationModel>> getCampaignDonors(int campaignId) async {
    final response = await _dio.get(ApiConstants.campaignDonors(campaignId));
    return _safeList(response.data).map((e) => DonorWithDonationModel.fromJson(e)).toList();
  }
}
