import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/campaign_model.dart';
import '../models/donation_model.dart';
import '../models/donation_with_campaign_model.dart';
import '../models/like_status_model.dart';
import '../models/top_donor_model.dart';

class CampaignRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  Future<List<Map<String, dynamic>>> getCities() async {
    final response = await _dio.get(ApiConstants.cities);
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _dio.get(ApiConstants.categories);
    return (response.data as List).cast<Map<String, dynamic>>();
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
    return (response.data as List).map((e) => CampaignModel.fromJson(e)).toList();
  }

  Future<List<CampaignModel>> getMyCampaigns() async {
    final response = await _dio.get(ApiConstants.myCampaigns);
    return (response.data as List).map((e) => CampaignModel.fromJson(e)).toList();
  }

  Future<CampaignModel> getCampaignDetail(int id) async {
    final response = await _dio.get('${ApiConstants.campaigns}/$id');
    return CampaignModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CampaignModel> createCampaign(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.campaigns, data: payload);
    return CampaignModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DonationModel> donate(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.donations, data: payload);
    return DonationModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<DonationWithCampaignModel>> getMyDonations() async {
    final response = await _dio.get(ApiConstants.myDonations);
    return (response.data as List).map((e) => DonationWithCampaignModel.fromJson(e)).toList();
  }

  Future<LikeStatusModel> toggleLike(int campaignId) async {
    final response = await _dio.post(
      '${ApiConstants.likes}/toggle',
      data: {'id_campania': campaignId},
    );
    return LikeStatusModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TopDonorModel>> getTopDonors({int limit = 5}) async {
    final response = await _dio.get(
      ApiConstants.topDonors,
      queryParameters: {'limit': limit},
    );
    return (response.data as List).map((e) => TopDonorModel.fromJson(e)).toList();
  }
}
