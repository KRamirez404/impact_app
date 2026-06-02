import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:get_storage/get_storage.dart';
import '../../app/routes/app_routes.dart';
import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';

class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();
  final GetStorage _storage = GetStorage();

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.read<String>(StorageKeys.token);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _storage.remove(StorageKeys.token);
            _storage.remove(StorageKeys.user);
            Get.offAllNamed(AppRoutes.login);
            Get.snackbar(
              'Sesión expirada',
              'Inicia sesión nuevamente',
              backgroundColor: const Color(0xFFD32F2F),
              colorText: const Color(0xFFFFFFFF),
            );
          }
          handler.next(error);
        },
      ),
    );

  Future<String> uploadFile(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await dio.post(ApiConstants.upload, data: formData);
    return response.data['url'] as String;
  }
}
