import 'package:get/get.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../campaigns/domain/usecases/get_campaigns_usecase.dart';
import '../../../campaigns/domain/usecases/get_campaign_detail_usecase.dart';
import '../../../campaigns/domain/entities/campaign_entity.dart';
import '../../../campaigns/infrastructure/models/campaign_model.dart';

class SupportController extends GetxController {
  final GetCampaignsUseCase getCampaignsUseCase;
  final GetCampaignDetailUseCase getCampaignDetailUseCase;
  final Dio _dio = DioClient.instance.dio;

  SupportController(this.getCampaignsUseCase, this.getCampaignDetailUseCase);

  final allCampaigns = <CampaignEntity>[].obs;
  final campaignDetail = Rxn<CampaignEntity>();
  final isLoading = false.obs;
  final isLoadingSummary = false.obs;

  final pendientesCount = 0.obs;
  final aprobadasCount = 0.obs;
  final rechazadasCount = 0.obs;

  final selectedTab = 0.obs;
  final searchQuery = ''.obs;

  List<CampaignEntity> get filteredCampaigns {
    var result = allCampaigns.toList();

    if (selectedTab.value == 0) {
      result = result.where((c) => c.estado == 'en_verificacion').toList();
    } else if (selectedTab.value == 1) {
      result = result.where((c) => c.estado == 'pausada').toList();
    } else if (selectedTab.value == 2) {
      result = result.where((c) => c.estado == 'activa').toList();
    }

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((c) =>
        c.titulo.toLowerCase().contains(query) ||
        c.descripcion.toLowerCase().contains(query) ||
        c.ciudadNombre.toLowerCase().contains(query) ||
        c.creadorNombre.toLowerCase().contains(query)
      ).toList();
    }

    return result;
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    await Future.wait([loadCampaigns(), loadSummary()]);
  }

  Future<void> loadSummary() async {
    try {
      isLoadingSummary.value = true;
      final response = await _dio.get(ApiConstants.supportSummary);
      final data = response.data as Map<String, dynamic>;
      pendientesCount.value = (data['pendientes'] ?? 0) as int;
      aprobadasCount.value = (data['aprobadas'] ?? 0) as int;
      rechazadasCount.value = (data['rechazadas'] ?? 0) as int;
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoadingSummary.value = false;
    }
  }

  Future<void> loadCampaigns() async {
    try {
      isLoading.value = true;
      final response = await _dio.get(ApiConstants.supportCampaigns);
      final list = (response.data as List)
          .map((e) => CampaignModel.fromJson(e as Map<String, dynamic>))
          .toList();
      allCampaigns.assignAll(list);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCampaignDetail(int id) async {
    try {
      isLoading.value = true;
      final detail = await getCampaignDetailUseCase(id);
      campaignDetail.value = detail;
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approve(int id) async {
    try {
      isLoading.value = true;
      await _dio.post(ApiConstants.supportApprove(id));
      Get.snackbar('Éxito', 'Campaña aprobada');
      await loadData();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reject(int id, String note) async {
    try {
      isLoading.value = true;
      await _dio.post(ApiConstants.supportReject(id), data: {'nota': note});
      Get.snackbar('Éxito', 'Campaña rechazada');
      await loadData();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void setTab(int index) {
    selectedTab.value = index;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }
}
