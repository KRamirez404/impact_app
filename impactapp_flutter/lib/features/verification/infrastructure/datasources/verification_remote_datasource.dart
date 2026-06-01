import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/support_model.dart';

class VerificationRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  Map<String, dynamic> _safeMap(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) {
      throw ServerException('Respuesta inválida del servidor');
    }
    return data;
  }

  Future<SupportModel> uploadSupport({
    required int idCampania,
    required String tipo,
    String? descripcion,
    String? filePath,
    String? url,
  }) async {
    final formData = FormData.fromMap({
      'id_campania': idCampania.toString(),
      'tipo': tipo,
      'descripcion': descripcion ?? '',
      if (url != null && url.isNotEmpty) 'url_o_ruta': url,
      if (filePath != null && filePath.isNotEmpty)
        'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(ApiConstants.supports, data: formData);
    return SupportModel.fromJson(_safeMap(response.data));
  }
}

