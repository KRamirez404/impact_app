import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../campaigns/domain/entities/campaign_entity.dart';
import '../controllers/support_controller.dart';

class SupportHomePage extends GetView<SupportController> {
  const SupportHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderSection(),
            _buildTabsSection(),
            Expanded(child: _buildCampaignList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF155DFC), Color(0xFF00A63E)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Panel de Soporte',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Verificación de campañas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.isLoadingSummary.value &&
                  controller.pendientesCount.value == 0) {
                return const SizedBox(
                  height: 43,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                );
              }
              return Row(
                children: [
                  _buildStatCard(
                      '${controller.pendientesCount.value}', 'Pendientes'),
                  const SizedBox(width: 8),
                  _buildStatCard(
                      '${controller.aprobadasCount.value}', 'Aprobada'),
                  const SizedBox(width: 8),
                  _buildStatCard(
                      '${controller.rechazadasCount.value}', 'Rechazado'),
                ],
              );
            }),
            const SizedBox(height: 12),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count $label',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        onChanged: controller.setSearchQuery,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF0A0A0A),
        ),
        decoration: const InputDecoration(
          hintText: 'Buscar campañas...',
          hintStyle: TextStyle(color: Color(0xFF717182)),
          prefixIcon: Icon(Icons.search, color: Color(0xFF99A1AF), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildTabsSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(33, 16, 0, 4),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0x1A000000), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => _buildSegmentedControl(
              labels: const ['Pendientes', 'Rechazadas', 'Activas'],
              selectedIndex: controller.selectedTab.value >= 0 &&
                      controller.selectedTab.value <= 2
                  ? controller.selectedTab.value
                  : -1,
              onSelect: controller.setTab,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => _buildFlatTab(
              label: 'Todas',
              isSelected: controller.selectedTab.value == 3,
              onTap: () => controller.setTab(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl({
    required List<String> labels,
    required int selectedIndex,
    required Function(int) onSelect,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFECECF0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              width: 110.87,
              height: 29,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                labels[i],
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Color(0xFF0A0A0A),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFlatTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : const Color(0xFFECECF0),
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: const Color(0xFFECECF0))
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: isSelected
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFF717182),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignList() {
    return Obx(() {
      if (controller.isLoading.value && controller.allCampaigns.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final campaigns = controller.filteredCampaigns;

      if (campaigns.isEmpty) {
        return const Center(
          child: Text(
            'No hay campañas',
            style: TextStyle(color: Color(0xFF717182)),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: campaigns.length,
        itemBuilder: (_, i) => _buildCampaignCard(campaigns[i]),
      );
    });
  }

  Widget _buildCampaignCard(CampaignEntity campaign) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x1A000000),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardImage(campaign),
          _buildCardContent(campaign),
        ],
      ),
    );
  }

  Widget _buildCardImage(CampaignEntity campaign) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: Container(
        height: 184,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _categoryColor(campaign.categoriaNombre).withValues(alpha: 0.7),
              _categoryColor(campaign.categoriaNombre),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 14,
              right: 16,
              child: _buildStatusBadge(campaign.estado),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String estado) {
    Color bgColor;
    String label;

    switch (estado) {
      case 'en_verificacion':
        bgColor = const Color(0xFFF0B100);
        label = 'Pendiente';
        break;
      case 'activa':
        bgColor = const Color(0xFF43A047);
        label = 'Activa';
        break;
      case 'pausada':
        bgColor = const Color(0xFFE53935);
        label = 'Rechazado';
        break;
      default:
        bgColor = const Color(0xFF99A1AF);
        label = estado;
    }

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(CampaignEntity campaign) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCategoryBadge(campaign.categoriaNombre),
              const SizedBox(width: 8),
              const Icon(Icons.location_on_outlined,
                  size: 12, color: Color(0xFF4A5565)),
              const SizedBox(width: 4),
              Text(
                campaign.ciudadNombre,
                style: const TextStyle(fontSize: 12, color: Color(0xFF4A5565)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            campaign.titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            campaign.descripcion,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4A5565),
              height: 1.33,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetadataSection(campaign),
          const SizedBox(height: 12),
          _buildActionButtons(campaign),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String categoryName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF43A047),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        categoryName,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMetadataSection(CampaignEntity campaign) {
    final organizador =
        '${campaign.creadorNombre} ${campaign.creadorApellido}'.trim();
    final fechaCreada = _formatDate(campaign.fechaInicio);
    final evidenciasCount = campaign.soportes.length;

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          _buildMetadataRow('Organizador:',
              organizador.isNotEmpty ? organizador : 'Desconocido'),
          const SizedBox(height: 6),
          _buildMetadataRow('Fecha creación:', fechaCreada,
              showCalendarIcon: true),
          const SizedBox(height: 6),
          _buildMetadataRow('Evidencias:', '$evidenciasCount documentos'),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value,
      {bool showCalendarIcon = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF4A5565)),
        ),
        if (showCalendarIcon)
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 12, color: Color(0xFF0A0A0A)),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0A0A0A),
                ),
              ),
            ],
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0A0A0A),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(CampaignEntity campaign) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Get.toNamed(
                '${AppRoutes.supportCampaignDetail}/${campaign.idCampania}'),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('Ver Detalles'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0A0A0A),
              side: const BorderSide(color: Color(0x1A000000)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 6),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF155DFC), Color(0xFF00A63E)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ElevatedButton(
              onPressed: () => Get.toNamed(
                  '${AppRoutes.supportCampaignDetail}/${campaign.idCampania}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Evaluar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _categoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'desastres naturales':
        return const Color(0xFFF97316);
      case 'salud':
        return const Color(0xFF22C55E);
      case 'educación':
        return const Color(0xFF3B82F6);
      case 'pobreza estructural':
        return const Color(0xFFA855F7);
      case 'desplazamiento forzado':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
