import 'package:get/get.dart';

import '../../../campaigns/domain/usecases/get_campaign_detail_usecase.dart';
import '../../../campaigns/domain/entities/campaign_entity.dart';
import '../../domain/usecases/approve_campaign_usecase.dart';
import '../../domain/usecases/reject_campaign_usecase.dart';
import '../../domain/usecases/get_support_summary_usecase.dart';
import '../../domain/usecases/get_support_campaigns_usecase.dart';

class SupportController extends GetxController {
  final GetCampaignDetailUseCase getCampaignDetailUseCase;
  final GetSupportCampaignsUseCase getSupportCampaignsUseCase;
  final GetSupportSummaryUseCase getSupportSummaryUseCase;
  final ApproveCampaignUseCase approveCampaignUseCase;
  final RejectCampaignUseCase rejectCampaignUseCase;

  SupportController(
    this.getCampaignDetailUseCase,
    this.getSupportCampaignsUseCase,
    this.getSupportSummaryUseCase,
    this.approveCampaignUseCase,
    this.rejectCampaignUseCase,
  );

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
      final summary = await getSupportSummaryUseCase();
      pendientesCount.value = summary.pendientes;
      aprobadasCount.value = summary.aprobadas;
      rechazadasCount.value = summary.rechazadas;
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoadingSummary.value = false;
    }
  }

  Future<void> loadCampaigns() async {
    try {
      isLoading.value = true;
      final list = await getSupportCampaignsUseCase();
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
      await approveCampaignUseCase(id);
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
      await rejectCampaignUseCase(id, note);
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
