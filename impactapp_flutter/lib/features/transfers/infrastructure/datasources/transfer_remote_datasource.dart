import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/bank_account_model.dart';
import '../models/transfer_model.dart';

class TransferRemoteDataSource {
  final Dio _dio;

  TransferRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  Map<String, dynamic> _map(dynamic data) {
    if (data is! Map) throw ServerException('Respuesta inválida del servidor');
    return Map<String, dynamic>.from(data);
  }

  Future<BankAccountModel> getBankAccount(int campaignId) async {
    final response = await _dio.get(
      ApiConstants.campaignBankAccount(campaignId),
    );
    return BankAccountModel.fromJson(_map(response.data));
  }

  Future<TransferModel> createTransfer(
    Map<String, dynamic> payload,
    String idempotencyKey,
  ) async {
    final response = await _dio.post(
      ApiConstants.transfers,
      data: payload,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return TransferModel.fromJson(_map(response.data));
  }

  Future<List<TransferModel>> getMyTransfers() async {
    final response = await _dio.get(ApiConstants.myTransfers);
    final data = _map(response.data);
    final items = data['items'];
    if (items is! List) {
      throw ServerException('Respuesta inválida del servidor');
    }
    return items.map((item) => TransferModel.fromJson(_map(item))).toList();
  }

  Future<TransferModel> getTransfer(int transferId) async {
    final response = await _dio.get(ApiConstants.transferDetail(transferId));
    return TransferModel.fromJson(_map(response.data));
  }

  Future<TransferModel> uploadReceipt(
    int transferId,
    String filePath, {
    required bool resubmit,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    await _dio.post(
      resubmit
          ? ApiConstants.transferResubmit(transferId)
          : ApiConstants.transferReceipt(transferId),
      data: form,
    );
    return getTransfer(transferId);
  }

  Future<Uint8List> downloadReceipt(int transferId) async {
    final response = await _dio.get<List<int>>(
      ApiConstants.transferReceipt(transferId),
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw ServerException('El comprobante descargado está vacío');
    }
    return Uint8List.fromList(data);
  }

  Future<List<TransferModel>> getSupportTransfers() async {
    final response = await _dio.get(ApiConstants.supportTransfers);
    final items = _map(response.data)['items'];
    if (items is! List) {
      throw ServerException('Respuesta inválida del servidor');
    }
    return items.map((item) => TransferModel.fromJson(_map(item))).toList();
  }

  Future<TransferModel> getSupportTransfer(int transferId) async {
    final response = await _dio.get(ApiConstants.supportTransfer(transferId));
    return TransferModel.fromJson(_map(response.data));
  }

  Future<TransferModel> claimSupportTransfer(int transferId, String key) async {
    final response = await _dio.post(
      ApiConstants.supportTransferAction(transferId, 'claim'),
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return TransferModel.fromJson(_map(response.data));
  }

  Future<TransferModel> approveSupportTransfer(
    int transferId,
    Map<String, dynamic> evidence,
    String key,
  ) async {
    final response = await _dio.post(
      ApiConstants.supportTransferAction(transferId, 'approve'),
      data: evidence,
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return TransferModel.fromJson(_map(response.data));
  }

  Future<TransferModel> rejectSupportTransfer(
    int transferId,
    String reason,
    String key,
  ) async {
    final response = await _dio.post(
      ApiConstants.supportTransferAction(transferId, 'reject'),
      data: {'motivo': reason},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return TransferModel.fromJson(_map(response.data));
  }

  Future<Uint8List> downloadSupportReceipt(int transferId) async {
    final response = await _dio.get<List<int>>(
      ApiConstants.supportTransferReceipt(transferId),
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw ServerException('El comprobante descargado está vacío');
    }
    return Uint8List.fromList(data);
  }
}
