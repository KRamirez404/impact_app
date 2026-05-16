import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/campaign_model.dart';
import '../models/donation_model.dart';

class CampaignRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

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
}

