import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../campaigns/domain/entities/campaign_entity.dart';
import '../../../campaigns/domain/entities/donation_with_campaign_entity.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile/stat_card.dart';
import '../widgets/profile/activity_card.dart';
import '../widgets/profile/activity_item.dart';
import '../widgets/profile/profile_tabs.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final AuthController controller = Get.find<AuthController>();
  final ProfileController profileController = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      body: Obx(
        () {
          final user = controller.user.value;
          if (user == null) return const Center(child: Text('Sin datos de usuario'));
          final fullName = '${user.nombre} ${user.apellido}'.trim();
          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildHeader(context, fullName, user.correo, user.biografia),
                      Obx(() => _buildStatsRow()),
                      const SizedBox(height: 20),
                      const ProfileTabs(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
              body: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: [
                        Obx(() {
                          if (profileController.isLoadingCampaigns.value &&
                              profileController.myCampaigns.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (profileController.myCampaigns.isEmpty) {
                            return const Center(child: Text('No tienes campañas creadas'));
                          }
                          final items = profileController.myCampaigns
                              .map(_activityFromCampaign)
                              .toList();
                          return _buildScrollableTabContent(items);
                        }),
                        Obx(() {
                          if (profileController.isLoadingDonations.value &&
                              profileController.myDonations.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (profileController.myDonations.isEmpty) {
                            return const Center(child: Text('No tienes donaciones registradas'));
                          }
                          final items = profileController.myDonations
                              .map(_activityFromDonation)
                              .toList();
                          return _buildScrollableTabContent(items);
                        }),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: controller.logout,
                          icon: const Icon(Icons.logout, size: 16, color: Color(0xFFD4183D)),
                          label: const Text('Cerrar sesión'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD4183D),
                            side: const BorderSide(color: Color(0xFFD4183D), width: 0.8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String email, String? bio) {
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'I';
    final bioText = (bio == null || bio.trim().isEmpty)
        ? 'Aún no has agregado una biografía.'
        : bio.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF43A047)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54, height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('I', style: TextStyle(fontFamily: 'Audiowide', fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Mi Perfil',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 4),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    child: Text(
                      initials,
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(email, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => Get.toNamed(AppRoutes.editProfile),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Editar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF43A047),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => Get.toNamed(AppRoutes.settings),
                            icon: const Icon(Icons.settings, size: 16),
                            label: const Text('Ajustes'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              bioText,
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final campaignsCount = profileController.myCampaigns.length;
    final donationsCount = profileController.myDonations.length;
    final totalDonated = profileController.myDonations.fold<double>(
      0,
      (total, donation) => total + donation.montoEstimado,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          StatCard(value: campaignsCount.toString(), label: 'Campañas', valueColor: const Color(0xFF1976D2)),
          const SizedBox(width: 12),
          StatCard(value: donationsCount.toString(), label: 'Donaciones', valueColor: const Color(0xFF43A047)),
          const SizedBox(width: 12),
          StatCard(value: _formatCompactCurrency(totalDonated), label: 'Donado', valueColor: const Color(0xFF1976D2)),
        ],
      ),
    );
  }

  Widget _buildScrollableTabContent(List<ProfileActivityItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < items.length - 1 ? 12 : 0),
          child: ActivityCard(item: items[index]),
        );
      },
    );
  }

  ProfileActivityItem _activityFromCampaign(CampaignEntity campaign) {
    final auditorName = campaign.auditorNombre == null
        ? null
        : '${campaign.auditorNombre} ${campaign.auditorApellido ?? ''}'.trim();
    return ProfileActivityItem(
      title: campaign.titulo,
      amount: campaign.metaMonetaria,
      date: _formatDate(campaign.fechaFin),
      status: _mapCampaignStatus(campaign.estado),
      campaignId: campaign.idCampania,
      rejectionNote: campaign.notaRevision,
      auditorName: auditorName?.isEmpty == true ? null : auditorName,
    );
  }

  ProfileActivityItem _activityFromDonation(DonationWithCampaignEntity donation) {
    final title = donation.campaignTitulo.isNotEmpty ? donation.campaignTitulo : 'Donación';
    return ProfileActivityItem(
      title: title,
      amount: donation.montoEstimado,
      date: _formatDate(donation.fechaDonacion),
      status: _mapCampaignStatus(donation.campaignEstado),
    );
  }

  String _mapCampaignStatus(String estado) {
    switch (estado) {
      case 'en_verificacion': return 'En verificación';
      case 'rechazada': return 'Rechazada';
      case 'pausada': return 'Rechazada';
      case 'finalizada': return 'Finalizada';
      case 'activa': return 'Activa';
      default: return 'Sin estado';
    }
  }

  String _formatDate(String isoDate) {
    try {
      final parsed = DateTime.parse(isoDate);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000) {
      final millones = (amount / 1000000).toStringAsFixed(1);
      return '\$${millones.replaceAll('.', ',')}M';
    }
    if (amount >= 1000) {
      final miles = (amount / 1000).toStringAsFixed(0);
      return '\$$miles.K';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }
}
