import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../domain/entities/campaign_entity.dart';
import '../../domain/usecases/create_campaign_usecase.dart';
import '../../domain/usecases/get_campaigns_usecase.dart';

class CampaignListController extends GetxController {
  CampaignListController({
    required this.getCampaignsUseCase,
    required this.createCampaignUseCase,
  });

  final GetCampaignsUseCase getCampaignsUseCase;
  final CreateCampaignUseCase createCampaignUseCase;

  final campaigns = <CampaignEntity>[].obs;
  final isLoading = false.obs;
  final selectedTipo = ''.obs;
  final selectedEstado = ''.obs;
  final selectedCiudad = RxnInt();
  final selectedCategoria = RxnInt();

  @override
  void onInit() {
    super.onInit();
    fetchCampaigns();
  }

  void _ok(String msg) => Get.snackbar('Éxito', msg, backgroundColor: Colors.green, colorText: Colors.white);
  void _err(String msg) => Get.snackbar('Error', msg, backgroundColor: Colors.red, colorText: Colors.white);

  Future<void> fetchCampaigns() async {
    try {
      isLoading.value = true;
      campaigns.assignAll(
        await getCampaignsUseCase(
          ciudad: selectedCiudad.value,
          categoria: selectedCategoria.value,
          tipoAyuda: selectedTipo.value.isEmpty ? null : selectedTipo.value,
          estado: selectedEstado.value.isEmpty ? null : selectedEstado.value,
        ),
      );
    } catch (e) {
      _err(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createCampaign(Map<String, dynamic> payload) async {
    try {
      isLoading.value = true;
      await createCampaignUseCase(payload);
      _ok('Campaña creada');
      Get.offNamed(AppRoutes.home);
      await fetchCampaigns();
    } catch (e) {
      _err(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

