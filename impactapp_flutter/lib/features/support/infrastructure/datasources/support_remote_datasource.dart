import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/support_summary_model.dart';
import '../../../campaigns/infrastructure/models/campaign_model.dart';

class SupportRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  Map<String, dynamic> _safeMap(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) {
      throw ServerException('Respuesta inválida del servidor');
    }
    return data;
  }

  List<CampaignModel> _safeCampaignList(dynamic data) {
    if (data == null || data is! List) {
      throw ServerException('Respuesta inválida del servidor');
    }
    return data.map((e) => CampaignModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SupportSummaryModel> getSummary() async {
    final response = await _dio.get(ApiConstants.supportSummary);
    return SupportSummaryModel.fromJson(_safeMap(response.data));
  }

  Future<List<CampaignModel>> getCampaigns() async {
    final response = await _dio.get(ApiConstants.supportCampaigns);
    return _safeCampaignList(response.data);
  }

  Future<void> approve(int campaignId) async {
    await _dio.post(ApiConstants.supportApprove(campaignId));
  }

  Future<void> reject(int campaignId, String note) async {
    await _dio.post(
      ApiConstants.supportReject(campaignId),
      data: {'nota': note},
    );
  }
}
