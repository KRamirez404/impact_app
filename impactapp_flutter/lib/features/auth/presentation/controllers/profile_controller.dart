import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../campaigns/domain/entities/campaign_entity.dart';
import '../../../campaigns/domain/entities/donation_with_campaign_entity.dart';
import '../../../campaigns/domain/usecases/get_my_campaigns_usecase.dart';
import '../../../campaigns/domain/usecases/get_my_donations_usecase.dart';

class ProfileController extends GetxController {
  ProfileController({
    required this.getMyCampaignsUseCase,
    required this.getMyDonationsUseCase,
  });

  final GetMyCampaignsUseCase getMyCampaignsUseCase;
  final GetMyDonationsUseCase getMyDonationsUseCase;

  final myCampaigns = <CampaignEntity>[].obs;
  final myDonations = <DonationWithCampaignEntity>[].obs;
  final isLoadingCampaigns = false.obs;
  final isLoadingDonations = false.obs;

  void _err(String msg) => Get.snackbar('Error', msg, backgroundColor: Colors.red, colorText: Colors.white);

  @override
  void onInit() {
    super.onInit();
    fetchMyCampaigns();
    fetchMyDonations();
  }

  Future<void> fetchMyCampaigns() async {
    try {
      isLoadingCampaigns.value = true;
      myCampaigns.assignAll(await getMyCampaignsUseCase());
    } catch (e) {
      _err(friendlyError(e));
    } finally {
      isLoadingCampaigns.value = false;
    }
  }

  Future<void> fetchMyDonations() async {
    try {
      isLoadingDonations.value = true;
      myDonations.assignAll(await getMyDonationsUseCase());
    } catch (e) {
      _err(friendlyError(e));
    } finally {
      isLoadingDonations.value = false;
    }
  }
}
