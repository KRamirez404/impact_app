import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/campaign_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../campaigns/presentation/controllers/campaign_list_controller.dart';


class HomePage extends StatelessWidget {
  HomePage({super.key});
  final CampaignListController campaignCtrl = Get.find<CampaignListController>();
  final AuthController authCtrl = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Obx(() {
              final campaigns = campaignCtrl.verifiedCampaigns;
              if (campaignCtrl.isLoading.value && campaignCtrl.campaigns.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(),
                    const SizedBox(height: 24),
                    _buildStatsRow(campaigns),
                    _buildTopDonadores(),
                    _buildNearGoalSection(campaigns),
                    _buildRecentCampaignsSection(campaigns),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }),
          ),
          const BottomNavBar(currentIndex: 0),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Color(0xFF1976D2),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('I',
                      style: TextStyle(
                          fontFamily: 'Audiowide',
                          fontSize: 20,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              const Text('ImpactApp',
                  style: TextStyle(
                      fontFamily: 'Audiowide',
                      fontSize: 18,
                      color: Colors.white)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1976D2), const Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final user = authCtrl.user.value;
            final name = user != null ? user.nombre.split(' ').first : '';
            return Text(
              '¡Hola, $name!',
              style: const TextStyle(
                fontFamily: 'Audiowide',
                fontSize: 20,
                color: Colors.white,
              ),
            );
          }),
          const SizedBox(height: 8),
          const Text(
            'Juntos podemos hacer la diferencia.\nExplora campañas y aporta tu granito de arena.',
            style: TextStyle(
              fontFamily: 'Montserrat Alternates',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: Color(0xFFFFEDD4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<dynamic> campaigns) {
    final activas = campaigns.where((c) => c.estado == 'activa').length;
    final verificadas = campaigns.where((c) => c.estado == 'activa' || c.estado == 'finalizada').length;
    final total = campaigns.length;
    final verificadasPorcentaje = total > 0 ? (verificadas * 100 ~/ total) : 0;
    final urgentes = campaigns.where((c) {
      if (c.estado != 'activa') return false;
      try {
        final fin = DateTime.parse(c.fechaFin);
        return fin.difference(DateTime.now()).inDays <= 7;
      } catch (_) {
        return false;
      }
    }).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _statCard(
            Icons.trending_up,
            'Activas',
            '$activas',
            const Color(0xFF1976D2),
          ),
          const SizedBox(width: 12),
          _statCard(
            Icons.check_circle_outline,
            'Verificadas',
            '$verificadasPorcentaje%',
            const Color(0xFF43A047),
          ),
          const SizedBox(width: 12),
          _statCard(
            Icons.local_fire_department_outlined,
            'Urgentes',
            '$urgentes',
            const Color(0xFFFF6900),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF717182),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDonadores() {
    final topDonors = [
      {'nombre': 'Fundación Éxito', 'monto': '\$12.5M', 'color': const Color(0xFFF59E0B)},
      {'nombre': 'Carlos M.', 'monto': '\$8.2M', 'color': const Color(0xFF3B82F6)},
      {'nombre': 'Ana G.', 'monto': '\$5.7M', 'color': const Color(0xFF22C55E)},
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined, size: 24, color: Color(0xFFF0B100)),
              const SizedBox(width: 8),
              const Text('Top Donadores',
                  style: TextStyle(fontSize: 18, color: Color(0xFF000000))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 185,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: topDonors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final donor = topDonors[i];
                return Container(
                  width: 124,
                  decoration: BoxDecoration(
                    color: donor['color'] as Color,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        child: Text(
                          (donor['nombre'] as String).substring(0, 1),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        donor['nombre'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      Text(
                        donor['monto'] as String,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearGoalSection(List<dynamic> campaigns) {
    final nearGoal = campaigns.where((c) {
      return c.porcentajeAvance >= 50 && c.porcentajeAvance < 100 && c.estado == 'activa';
    }).toList();

    if (nearGoal.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, size: 20, color: Color(0xFFFF6900)),
              const SizedBox(width: 8),
              const Text('Por alcanzar la meta',
                  style: TextStyle(fontSize: 18, color: Color(0xFF0A0A0A))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 500,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nearGoal.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                return SizedBox(
                  width: 340,
                  child: CampaignCard(
                    campaign: nearGoal[i],
                    onTap: () => Get.toNamed('${AppRoutes.campaignDetail}/${nearGoal[i].idCampania}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCampaignsSection(List<dynamic> campaigns) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Campañas Recientes',
                  style: TextStyle(fontSize: 18, color: Color(0xFF0A0A0A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${campaigns.length} campañas',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0A0A0A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...campaigns.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CampaignCard(
                  campaign: c,
                  onTap: () => Get.toNamed('${AppRoutes.campaignDetail}/${c.idCampania}'),
                ),
              )),
        ],
      ),
    );
  }
}
