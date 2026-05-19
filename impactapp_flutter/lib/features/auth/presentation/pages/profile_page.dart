import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../campaigns/domain/entities/campaign_entity.dart';
import '../../../campaigns/domain/entities/donation_with_campaign_entity.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

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
          return Column(
            children: [
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      _buildHeader(context, fullName, user.correo),
                      Obx(() => _buildStatsRow()),
                      const SizedBox(height: 20),
                      _buildTabs(),
                      const SizedBox(height: 12),
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
                              return _buildActivityList(items);
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
                              return _buildActivityList(items);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: CustomButton(text: 'Cerrar sesión', onPressed: controller.logout),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String email) {
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'I';
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
                  width: 54,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'I',
                      style: TextStyle(
                        fontFamily: 'Audiowide',
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
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
                  width: 80,
                  height: 80,
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
                      Text(
                        name,
                        style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
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
                            onPressed: () {},
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
              'Apasionada por ayudar a mi comunidad. Creo en la solidaridad y el impacto positivo.',
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
          _StatCard(
            value: campaignsCount.toString(),
            label: 'Campañas',
            valueColor: const Color(0xFF1976D2),
          ),
          const SizedBox(width: 12),
          _StatCard(
            value: donationsCount.toString(),
            label: 'Donaciones',
            valueColor: const Color(0xFF43A047),
          ),
          const SizedBox(width: 12),
          _StatCard(
            value: _formatCompactCurrency(totalDonated),
            label: 'Donado',
            valueColor: const Color(0xFF1976D2),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFECECF0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          labelColor: const Color(0xFF0A0A0A),
          unselectedLabelColor: const Color(0xFF0A0A0A),
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Mis Campañas'),
            Tab(text: 'Donaciones'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(List<_ProfileActivityItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _ActivityCard(item: items[index]),
    );
  }

  _ProfileActivityItem _activityFromCampaign(CampaignEntity campaign) {
    return _ProfileActivityItem(
      title: campaign.titulo,
      amount: campaign.metaMonetaria,
      date: _formatDate(campaign.fechaFin),
      status: _mapCampaignStatus(campaign.estado),
    );
  }

  _ProfileActivityItem _activityFromDonation(DonationWithCampaignEntity donation) {
    final title = donation.campaignTitulo.isNotEmpty ? donation.campaignTitulo : 'Donación';
    return _ProfileActivityItem(
      title: title,
      amount: donation.montoEstimado,
      date: _formatDate(donation.fechaDonacion),
      status: _mapCampaignStatus(donation.campaignEstado),
    );
  }

  String _mapCampaignStatus(String estado) {
    switch (estado) {
      case 'en_verificacion':
        return 'En verificación';
      case 'pausada':
        return 'Rechazada';
      case 'finalizada':
        return 'Finalizada';
      case 'activa':
        return 'Activa';
      default:
        return 'Sin estado';
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4)),
            BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 22, color: valueColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF717182))),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final _ProfileActivityItem item;

  Color _badgeBg() {
    if (item.status == 'Finalizada') return const Color(0xFFF0FDF4);
    if (item.status == 'Activa') return const Color(0xFFE0F2FE);
    if (item.status == 'En verificación') return const Color(0xFFFFF7ED);
    if (item.status == 'Rechazada') return const Color(0xFFFEE2E2);
    return const Color(0xFFF1F5F9);
  }

  Color _badgeBorder() {
    if (item.status == 'Finalizada') return const Color(0xFFB9F8CF);
    if (item.status == 'Activa') return const Color(0xFFBAE6FD);
    if (item.status == 'En verificación') return const Color(0xFFFED7AA);
    if (item.status == 'Rechazada') return const Color(0xFFFECACA);
    return const Color(0xFFE2E8F0);
  }

  Color _badgeText() {
    if (item.status == 'Finalizada') return const Color(0xFF008236);
    if (item.status == 'Activa') return const Color(0xFF0369A1);
    if (item.status == 'En verificación') return const Color(0xFFC2410C);
    if (item.status == 'Rechazada') return const Color(0xFFB91C1C);
    return const Color(0xFF334155);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.image_outlined, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(item.amount),
                  style: const TextStyle(fontSize: 18, color: Color(0xFF43A047), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Color(0xFF717182)),
                    const SizedBox(width: 6),
                    Text(item.date, style: const TextStyle(fontSize: 12, color: Color(0xFF717182))),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(fontSize: 12, color: Color(0xFF717182))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _badgeBg(),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _badgeBorder(), width: 0.8),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(fontSize: 12, color: _badgeText(), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      final millones = (amount / 1000000).toStringAsFixed(1);
      return '\$${millones.replaceAll('.', ',')}M';
    }
    if (amount >= 1000) {
      final miles = (amount / 1000).toStringAsFixed(0);
      return '\$$miles.000';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }
}

class _ProfileActivityItem {
  const _ProfileActivityItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
  });

  final String title;
  final double amount;
  final String date;
  final String status;
}
