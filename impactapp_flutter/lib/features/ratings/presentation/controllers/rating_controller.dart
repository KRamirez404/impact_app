import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/usecases/rate_campaign_usecase.dart';

class RatingController extends GetxController {
  RatingController(this.rateCampaignUseCase);
  final RateCampaignUseCase rateCampaignUseCase;

  final isLoading = false.obs;
  final rating = 5.0.obs;

  void _ok(String msg) => Get.snackbar('Éxito', msg, backgroundColor: Colors.green, colorText: Colors.white);
  void _err(String msg) => Get.snackbar('Error', msg, backgroundColor: Colors.red, colorText: Colors.white);

  Future<void> submit({
    required int idCampania,
    required String comentario,
  }) async {
    try {
      isLoading.value = true;
      await rateCampaignUseCase(
        idCampania: idCampania,
        calificacion: rating.value.round(),
        comentario: comentario,
      );
      _ok('Valoración registrada');
      Get.back();
    } catch (e) {
      _err(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

