import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../campaigns/domain/entities/top_donor_entity.dart';
import '../../../campaigns/domain/usecases/get_top_donors_usecase.dart';

class HomeController extends GetxController {
  HomeController({required this.getTopDonorsUseCase});

  final GetTopDonorsUseCase getTopDonorsUseCase;

  final topDonors = <TopDonorEntity>[].obs;
  final isLoadingTopDonors = false.obs;

  void _err(String msg) => Get.snackbar('Error', msg, backgroundColor: Colors.red, colorText: Colors.white);

  @override
  void onInit() {
    super.onInit();
    fetchTopDonors();
  }

  Future<void> fetchTopDonors() async {
    try {
      isLoadingTopDonors.value = true;
      topDonors.assignAll(await getTopDonorsUseCase(limit: 5));
    } catch (e) {
      _err(e.toString());
    } finally {
      isLoadingTopDonors.value = false;
    }
  }
}
