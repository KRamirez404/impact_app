import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  final searchQuery = ''.obs;
  final selectedCategoryLabels = <String>[].obs;
  final selectedCityLabel = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchCampaigns();
  }

  void _ok(String msg) => Get.snackbar('Éxito', msg, backgroundColor: Colors.green, colorText: Colors.white);
  void _err(String msg) => Get.snackbar('Error', msg, backgroundColor: Colors.red, colorText: Colors.white);

  bool _isVerified(CampaignEntity campaign) {
    return campaign.estado == 'activa' || campaign.estado == 'finalizada';
  }

  List<CampaignEntity> get verifiedCampaigns {
    return campaigns.where(_isVerified).toList();
  }

  List<CampaignEntity> get filteredCampaigns {
    final query = searchQuery.value.trim().toLowerCase();
    return verifiedCampaigns.where((campaign) {
      final matchesQuery = query.isEmpty ||
          campaign.titulo.toLowerCase().contains(query) ||
          campaign.descripcion.toLowerCase().contains(query) ||
          campaign.ciudadNombre.toLowerCase().contains(query) ||
          campaign.categoriaNombre.toLowerCase().contains(query);
      final matchesCiudad = selectedCityLabel.value == null ||
          campaign.ciudadNombre.toLowerCase() == selectedCityLabel.value!.toLowerCase();
      final matchesCategoria = selectedCategoryLabels.isEmpty ||
          selectedCategoryLabels.any(
            (label) => campaign.categoriaNombre.toLowerCase() == label.toLowerCase(),
          );

      return matchesQuery && matchesCiudad && matchesCategoria;
    }).toList();
  }

  void setSearchQuery(String value) {
    searchQuery.value = value;
  }

  void toggleCategoryLabel(String label) {
    if (selectedCategoryLabels.contains(label)) {
      selectedCategoryLabels.remove(label);
    } else {
      selectedCategoryLabels.add(label);
    }
  }

  void setFilters({
    List<String>? categoryLabels,
    String? cityLabel,
  }) {
    selectedCategoryLabels.assignAll(categoryLabels ?? const []);
    selectedCityLabel.value = cityLabel;
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedCategoryLabels.clear();
    selectedCityLabel.value = null;
  }

  Future<void> fetchCampaigns() async {
    try {
      isLoading.value = true;
      campaigns.assignAll(await getCampaignsUseCase());
    } catch (e) {
      _err(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void updateCampaign(CampaignEntity updatedCampaign) {
    final index = campaigns.indexWhere((campaign) => campaign.idCampania == updatedCampaign.idCampania);
    if (index == -1) return;

    campaigns[index] = updatedCampaign;
    campaigns.refresh();
  }

  Future<CampaignEntity?> createCampaign(Map<String, dynamic> payload) async {
    try {
      isLoading.value = true;
      final campaign = await createCampaignUseCase(payload);
      _ok('Campaña creada');
      await fetchCampaigns();
      return campaign;
    } catch (e) {
      _err(e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
