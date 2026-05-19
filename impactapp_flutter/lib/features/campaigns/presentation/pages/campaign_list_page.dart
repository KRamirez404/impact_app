import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/campaign_card.dart';
import '../controllers/campaign_list_controller.dart';

class CampaignListPage extends StatelessWidget {
  CampaignListPage({super.key});
  final CampaignListController controller = Get.find<CampaignListController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campañas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed(AppRoutes.createCampaign),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Get.toNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: Obx(
        () {
          if (controller.isLoading.value && controller.campaigns.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.campaigns.isEmpty) {
            return const Center(child: Text('No hay campañas disponibles'));
          }
          return RefreshIndicator(
            onRefresh: controller.fetchCampaigns,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.campaigns.length,
              itemBuilder: (_, index) {
                final item = controller.campaigns[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CampaignCard(
                    campaign: item,
                    onTap: () => Get.toNamed('${AppRoutes.campaignDetail}/${item.idCampania}'),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
