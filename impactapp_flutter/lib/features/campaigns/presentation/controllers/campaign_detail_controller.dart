import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/campaign_entity.dart';
import '../../domain/usecases/donate_usecase.dart';
import '../../domain/usecases/get_campaign_detail_usecase.dart';

class CampaignDetailController extends GetxController {
  CampaignDetailController({
    required this.getCampaignDetailUseCase,
    required this.donateUseCase,
  });

  final GetCampaignDetailUseCase getCampaignDetailUseCase;
  final DonateUseCase donateUseCase;

  final isLoading = false.obs;
  final campaign = Rxn<CampaignEntity>();

  void _ok(String msg) => Get.snackbar('Éxito', msg, backgroundColor: Colors.green, colorText: Colors.white);
  void _err(String msg) => Get.snackbar('Error', msg, backgroundColor: Colors.red, colorText: Colors.white);

  Future<void> loadCampaign(int id) async {
    try {
      isLoading.value = true;
      campaign.value = await getCampaignDetailUseCase(id);
    } catch (e) {
      _err(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> donate(Map<String, dynamic> payload) async {
    try {
      isLoading.value = true;
      await donateUseCase(payload);
      _ok('Donación registrada');
      await loadCampaign(payload['id_campania'] as int);
    } catch (e) {
      _err(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

