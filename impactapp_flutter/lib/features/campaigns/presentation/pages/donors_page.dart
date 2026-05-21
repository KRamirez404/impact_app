import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/donor_with_donation_entity.dart';
import '../controllers/donors_controller.dart';

class DonorsPage extends StatelessWidget {
  final int campaignId;
  final String campaignTitle;

  const DonorsPage({
    super.key,
    required this.campaignId,
    required this.campaignTitle,
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
              _buildHeader(controller),
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

  Widget _buildHeader(DonorsController controller) {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          color: const Color(0xFFE2E8F0),
          child: const Center(
            child: Icon(Icons.image_outlined, size: 48, color: Color(0xFF64748B)),
          ),
        ),
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
          top: 16,
          left: 16,
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Activa',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
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
                    Text(
                      'Verificada',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF717182)),
              const SizedBox(width: 4),
              const Text(
                'Barranquilla',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF717182),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.people_outline, size: 16, color: Color(0xFF717182)),
              const SizedBox(width: 4),
              Obx(() => Text(
                    '${controller.donors.length} donantes',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Color(0xFF717182),
                    ),
                  )),
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
                  Obx(() => Text(
                        _formatCurrency(controller.totalRecaudado.value),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: AppColors.primary,
                        ),
                      )),
                  const SizedBox(height: 4),
                  const Text(
                    'Total recaudado',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xFF717182),
                    ),
                  ),
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
                  Obx(() => Text(
                        _formatCurrency(controller.promedioDonacion.value),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: Color(0xFF43A047),
                        ),
                      )),
                  const SizedBox(height: 4),
                  const Text(
                    'Promedio',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xFF717182),
                    ),
                  ),
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
                const Text(
                  'Donaciones económicas:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Color(0xFF717182),
                  ),
                ),
                Obx(() => Text(
                      '${controller.donacionesEconomicas.value}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Donaciones físicas:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Color(0xFF717182),
                  ),
                ),
                Obx(() => Text(
                      '${controller.donacionesFisicas.value}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    )),
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
          Obx(() => Text(
                'Tus donantes (${controller.donors.length})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              )),
          const SizedBox(height: 12),
          Obx(() => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.donors.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final donor = controller.donors[index];
                  return _buildDonorCard(donor);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildDonorCard(DonorWithDonationEntity donor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Icon(Icons.person_outline, size: 24, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            donor.nombreCompleto,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (donor.esDonacionFisica)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.cardBorder, width: 1.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.textPrimary),
                                SizedBox(width: 4),
                                Text(
                                  'Donación Física',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatCurrency(donor.montoEstimado),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(donor.fechaDonacion),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: Color(0xFF717182),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (donor.descripcion != null && donor.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '"${donor.descripcion}"',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF717182),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
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

  String _formatDate(String isoDate) {
    try {
      final parsed = DateTime.parse(isoDate);
      final months = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      final hour = parsed.hour > 12 ? parsed.hour - 12 : parsed.hour;
      final period = parsed.hour >= 12 ? 'p. m.' : 'a. m.';
      return '${parsed.day} de ${months[parsed.month - 1]}, ${hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return isoDate;
    }
  }
}
