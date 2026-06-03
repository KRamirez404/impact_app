import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../controllers/donors_controller.dart';
import '../widgets/donors/donor_card.dart';

class DonorsPage extends StatelessWidget {
  final int campaignId;
  final String campaignTitle;
  final String? campaignImageUrl;

  const DonorsPage({
    super.key,
    required this.campaignId,
    required this.campaignTitle,
    this.campaignImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DonorsController>();
    controller.loadDonors(campaignId, campaignTitle);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.donors.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    _buildCampaignInfo(controller),
                    _buildStatsCards(controller),
                    _buildSummaryCard(controller),
                    _buildDonorsList(controller),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    final hasImage = campaignImageUrl != null && campaignImageUrl!.isNotEmpty;
    final normalizedUrl = hasImage && campaignImageUrl!.startsWith('/')
        ? '${ApiConstants.baseUrl.replaceAll('/api', '')}$campaignImageUrl'
        : campaignImageUrl;
    return Stack(
      children: [
        if (hasImage)
          Image.network(
            normalizedUrl!,
            height: 200, width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _headerPlaceholder(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _headerPlaceholder();
            },
          )
        else
          _headerPlaceholder(),
        Container(
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x80000000), Colors.transparent],
            ),
          ),
        ),
        Positioned(
          top: 16, left: 16,
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            ),
          ),
        ),
        Positioned(
          top: 16, right: 16,
          child: Row(
            children: [
              _badge('Activa', const Color(0xFF43A047)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A63E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Verificada',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerPlaceholder() {
    return Container(
      height: 200, width: double.infinity,
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Color(0xFF64748B)),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
        style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12, color: Colors.white)),
    );
  }

  Widget _buildCampaignInfo(DonorsController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.campaignTitle.value,
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 20, color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF717182)),
              const SizedBox(width: 4),
              const Text('Barranquilla',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14, color: Color(0xFF717182))),
              const SizedBox(width: 16),
              const Icon(Icons.people_outline, size: 16, color: Color(0xFF717182)),
              const SizedBox(width: 4),
              Obx(() => Text('${controller.donors.length} donantes',
                  style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14, color: Color(0xFF717182)))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(DonorsController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder, width: 1.18),
              ),
              child: Column(
                children: [
                  const Icon(Icons.volunteer_activism_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(height: 8),
                  Obx(() => Text(_formatCurrency(controller.totalRecaudado.value),
                      style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24, color: AppColors.primary))),
                  const SizedBox(height: 4),
                  const Text('Total recaudado',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 12, color: Color(0xFF717182))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder, width: 1.18),
              ),
              child: Column(
                children: [
                  const Icon(Icons.calculate_outlined, color: Color(0xFF43A047), size: 20),
                  const SizedBox(height: 8),
                  Obx(() => Text(_formatCurrency(controller.promedioDonacion.value),
                      style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24, color: Color(0xFF43A047)))),
                  const SizedBox(height: 4),
                  const Text('Promedio',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 12, color: Color(0xFF717182))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(DonorsController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 1.18),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Donaciones económicas:',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14, color: Color(0xFF717182))),
                Obx(() => Text('${controller.donacionesEconomicas.value}',
                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Donaciones físicas:',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14, color: Color(0xFF717182))),
                Obx(() => Text('${controller.donacionesFisicas.value}',
                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonorsList(DonorsController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Text('Tus donantes (${controller.donors.length})',
              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary))),
          const SizedBox(height: 12),
          Obx(() => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.donors.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => DonorCard(donor: controller.donors[index]),
          )),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '\$ ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}
