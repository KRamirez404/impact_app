import 'package:get/get.dart';
import '../../domain/entities/donor_with_donation_entity.dart';
import '../../domain/usecases/get_campaign_donors_usecase.dart';

class DonorsController extends GetxController {
  final GetCampaignDonorsUseCase getCampaignDonorsUseCase;

  DonorsController({required this.getCampaignDonorsUseCase});

  final donors = <DonorWithDonationEntity>[].obs;
  final isLoading = false.obs;
  final campaignTitle = ''.obs;
  final totalRecaudado = 0.0.obs;
  final promedioDonacion = 0.0.obs;
  final donacionesEconomicas = 0.obs;
  final donacionesFisicas = 0.obs;

  Future<void> loadDonors(int campaignId, String title) async {
    isLoading.value = true;
    campaignTitle.value = title;
    try {
      final result = await getCampaignDonorsUseCase(campaignId);
      donors.value = result;
      _calculateStats();
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los donadores');
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateStats() {
    totalRecaudado.value = donors.fold<double>(
      0,
      (sum, d) => sum + d.montoEstimado,
    );
    promedioDonacion.value = donors.isNotEmpty
        ? totalRecaudado.value / donors.length
        : 0;
    donacionesEconomicas.value =
        donors.where((d) => d.tipo == 'economica').length;
    donacionesFisicas.value =
        donors.where((d) => d.tipo != 'economica').length;
  }
}
