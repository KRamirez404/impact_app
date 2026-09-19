import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../campaigns/domain/usecases/get_campaign_detail_usecase.dart';
import '../../../campaigns/domain/entities/campaign_entity.dart';
import '../../domain/usecases/approve_campaign_usecase.dart';
import '../../domain/usecases/reject_campaign_usecase.dart';
import '../../domain/usecases/invalidate_campaign_usecase.dart';
import '../../domain/usecases/delete_campaign_usecase.dart';
import '../../domain/usecases/restore_campaign_usecase.dart';
import '../../domain/usecases/get_support_summary_usecase.dart';
import '../../domain/usecases/get_support_campaigns_usecase.dart';

class SupportController extends GetxController with WidgetsBindingObserver {
  final GetCampaignDetailUseCase getCampaignDetailUseCase;
  final GetSupportCampaignsUseCase getSupportCampaignsUseCase;
  final GetSupportSummaryUseCase getSupportSummaryUseCase;
  final ApproveCampaignUseCase approveCampaignUseCase;
  final RejectCampaignUseCase rejectCampaignUseCase;
  final InvalidateCampaignUseCase invalidateCampaignUseCase;
  final DeleteCampaignUseCase deleteCampaignUseCase;
  final RestoreCampaignUseCase restoreCampaignUseCase;

  SupportController(
    this.getCampaignDetailUseCase,
    this.getSupportCampaignsUseCase,
    this.getSupportSummaryUseCase,
    this.approveCampaignUseCase,
    this.rejectCampaignUseCase,
    this.invalidateCampaignUseCase,
    this.deleteCampaignUseCase,
    this.restoreCampaignUseCase,
  );

  final allCampaigns = <CampaignEntity>[].obs;
  final campaignDetail = Rxn<CampaignEntity>();
  final isLoading = false.obs;
  final isLoadingSummary = false.obs;

  final pendientesCount = 0.obs;
  final aprobadasCount = 0.obs;
  final rechazadasCount = 0.obs;
  final eliminadasCount = 0.obs;

  final selectedTab = 0.obs;
  final searchQuery = ''.obs;

  static const _pollInterval = Duration(seconds: 15);
  Timer? _pollTimer;
  bool _isRefreshing = false;

  void _showError(Object e) {
    var message = e.toString();
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) {
        message = data['error'].toString();
      } else if (e.response?.statusCode != null) {
        message = 'No se pudo completar la acción (${e.response?.statusCode})';
      }
    }
    Get.snackbar(
      'Error',
      message,
      backgroundColor: const Color(0xFFD32F2F),
      colorText: const Color(0xFFFFFFFF),
    );
  }

  List<CampaignEntity> get filteredCampaigns {
    List<CampaignEntity> result;

    if (selectedTab.value == 4) {
      result = allCampaigns.where((c) => c.eliminada).toList();
    } else {
      final visible = allCampaigns.where((c) => !c.eliminada).toList();
      if (selectedTab.value == 0) {
        result = visible.where((c) => c.estado == 'en_verificacion').toList();
      } else if (selectedTab.value == 1) {
        result = visible.where((c) => c.estado == 'pausada').toList();
      } else if (selectedTab.value == 2) {
        result = visible.where((c) => c.estado == 'activa').toList();
      } else {
        result = visible;
      }
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
    WidgetsBinding.instance.addObserver(this);
    loadData();
    _startPolling();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshData();
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => refreshData());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> loadData() async {
    await Future.wait([loadCampaigns(), loadSummary()]);
  }

  Future<void> refreshData() async {
    if (_isRefreshing || isLoading.value) return;
    _isRefreshing = true;
    try {
      final list = await getSupportCampaignsUseCase();
      final summary = await getSupportSummaryUseCase();
      allCampaigns.assignAll(list);
      pendientesCount.value = summary.pendientes;
      aprobadasCount.value = summary.aprobadas;
      rechazadasCount.value = summary.rechazadas;
      eliminadasCount.value = summary.eliminadas;
    } catch (_) {
      // Refresco silencioso: no interrumpir al usuario con errores de red.
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> loadSummary() async {
    try {
      isLoadingSummary.value = true;
      final summary = await getSupportSummaryUseCase();
      pendientesCount.value = summary.pendientes;
      aprobadasCount.value = summary.aprobadas;
      rechazadasCount.value = summary.rechazadas;
      eliminadasCount.value = summary.eliminadas;
    } catch (e) {
      _showError(e);
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
      _showError(e);
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
      _showError(e);
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
      _showError(e);
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
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> invalidateCampaign(int id, String motivo) async {
    try {
      isLoading.value = true;
      await invalidateCampaignUseCase(id, motivo);
      Get.snackbar('Éxito', 'Campaña invalidada');
      await loadData();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCampaign(int id, String motivo) async {
    try {
      isLoading.value = true;
      await deleteCampaignUseCase(id, motivo);
      Get.snackbar('Éxito', 'Campaña eliminada');
      await loadData();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restoreCampaign(int id) async {
    try {
      isLoading.value = true;
      await restoreCampaignUseCase(id);
      Get.snackbar('Éxito', 'Campaña restaurada');
      await loadData();
    } catch (e) {
      _showError(e);
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
