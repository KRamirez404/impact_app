import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/campaign_entity.dart';
import '../../domain/usecases/toggle_like_usecase.dart';
import '../../domain/usecases/donate_usecase.dart';
import '../../domain/usecases/get_campaign_detail_usecase.dart';
import 'campaign_list_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class CampaignDetailController extends GetxController {
  CampaignDetailController({
    required this.getCampaignDetailUseCase,
    required this.donateUseCase,
    required this.toggleLikeUseCase,
  });

  final GetCampaignDetailUseCase getCampaignDetailUseCase;
  final DonateUseCase donateUseCase;
  final ToggleLikeUseCase toggleLikeUseCase;

  final isLoading = false.obs;
  final isLiking = false.obs;
  final campaign = Rxn<CampaignEntity>();

  void _ok(String msg) => Get.snackbar('Éxito', msg, backgroundColor: Colors.green, colorText: Colors.white);
  void _err(String msg) => Get.snackbar('Error', msg, backgroundColor: Colors.red, colorText: Colors.white);

  void _syncCampaignLists(CampaignEntity updatedCampaign) {
    if (!Get.isRegistered<CampaignListController>()) return;

    Get.find<CampaignListController>().updateCampaign(updatedCampaign);
  }

  CampaignEntity _applyDonation(CampaignEntity currentCampaign, Map<String, dynamic> payload) {
    final tipo = (payload['tipo'] ?? '').toString();
    final amount = (payload['monto_estimado'] as num?)?.toDouble() ?? 0;
    var updatedProgress = currentCampaign.porcentajeAvance;

    if (tipo == 'economica' && currentCampaign.metaMonetaria > 0 && amount > 0) {
      updatedProgress = (updatedProgress + (amount / currentCampaign.metaMonetaria) * 100).clamp(0, 100).toDouble();
    }

    return currentCampaign.copyWith(
      porcentajeAvance: updatedProgress,
      donantesCount: currentCampaign.donantesCount + 1,
    );
  }

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
      final currentCampaign = campaign.value;
      if (currentCampaign != null && currentCampaign.idCampania == payload['id_campania']) {
        final updatedCampaign = _applyDonation(currentCampaign, payload);
        campaign.value = updatedCampaign;
        _syncCampaignLists(updatedCampaign);
      }
      _ok('Donación registrada');
    } catch (e) {
      _err(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleLike(int campaignId) async {
    final authReady = Get.isRegistered<AuthController>() &&
        Get.find<AuthController>().user.value != null;
    if (!authReady) {
      _err('Debes iniciar sesión para dar like');
      return;
    }
    try {
      isLiking.value = true;
      final result = await toggleLikeUseCase(campaignId);
      final currentCampaign = campaign.value;
      if (currentCampaign != null && currentCampaign.idCampania == campaignId) {
        final updatedCampaign = currentCampaign.copyWith(
          likesCount: result.likesCount,
          likedByMe: result.liked,
        );
        campaign.value = updatedCampaign;
        _syncCampaignLists(updatedCampaign);
      }
    } catch (e) {
      _err(e.toString());
    } finally {
      isLiking.value = false;
    }
  }
}
