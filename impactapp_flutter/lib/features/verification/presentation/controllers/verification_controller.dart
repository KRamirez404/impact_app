import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/usecases/upload_support_usecase.dart';

class VerificationController extends GetxController {
  VerificationController(this.uploadSupportUseCase);
  final UploadSupportUseCase uploadSupportUseCase;

  final isLoading = false.obs;
  final selectedType = 'imagen'.obs;
  final filePath = ''.obs;
  final link = ''.obs;

  void _ok(String msg) => Get.snackbar('Éxito', msg, backgroundColor: Colors.green, colorText: Colors.white);
  void _err(String msg) => Get.snackbar('Error', msg, backgroundColor: Colors.red, colorText: Colors.white);

  Future<void> submit({
    required int idCampania,
    required String descripcion,
  }) async {
    try {
      isLoading.value = true;
      await uploadSupportUseCase(
        idCampania: idCampania,
        tipo: selectedType.value,
        descripcion: descripcion,
        filePath: filePath.value.isEmpty ? null : filePath.value,
        url: link.value.isEmpty ? null : link.value,
      );
      _ok('Soporte cargado correctamente');
      Get.back();
    } catch (e) {
      _err(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

