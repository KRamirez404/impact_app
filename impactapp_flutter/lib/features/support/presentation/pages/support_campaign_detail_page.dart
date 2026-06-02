import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../campaigns/domain/entities/campaign_entity.dart';
import '../controllers/support_controller.dart';
import '../widgets/support_evaluation_dialog.dart';

class SupportCampaignDetailPage extends StatefulWidget {
  const SupportCampaignDetailPage({super.key});

  @override
  State<SupportCampaignDetailPage> createState() => _SupportCampaignDetailPageState();
}

class _SupportCampaignDetailPageState extends State<SupportCampaignDetailPage> {
  late final SupportController controller;
  late final int _id;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SupportController>();
    _id = int.parse(Get.parameters['id'] ?? '0');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadCampaignDetail(_id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final c = controller.campaignDetail.value;
          if (c == null) {
            return const Center(child: Text('No se encontró la campaña'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(c.titulo, c.estado, c.categoriaNombre),
                      _buildImagesSection(c.soportes),
                      _buildDivider(),
                      _buildDescriptionSection(c.descripcion),
                      _buildInfoGrid(c),
                      _buildDivider(),
                      _buildEvidenciasSection(c.soportes),
                      _buildDivider(),
                      if (c.estado == 'pausada') ...[
                        _buildVerificationHistory(c),
                        _buildDivider(),
                      ],
                      _buildCollectionPointsSection(c.puntosRecoleccion),
                      _buildBottomPadding(),
                    ],
                  ),
                ),
              ),
              if (c.estado == 'en_verificacion') _buildActionButtons(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader(String titulo, String estado, String categoria) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A0A0A),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Get.back(),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, size: 16, color: Color(0xB30A0A0A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusBadge(estado),
              const SizedBox(width: 8),
              _buildCategoryBadge(categoria),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String estado) {
    Color bgColor;
    String label;
    IconData icon;

    switch (estado) {
      case 'en_verificacion':
        bgColor = const Color(0xFFF0B100);
        label = 'Pendiente';
        icon = Icons.schedule;
        break;
      case 'activa':
        bgColor = const Color(0xFF00A63E);
        label = 'Verificada';
        icon = Icons.check;
        break;
      case 'pausada':
        bgColor = const Color(0xFFFB2C36);
        label = 'Rechazada';
        icon = Icons.close;
        break;
      default:
        bgColor = const Color(0xFF99A1AF);
        label = estado;
        icon = Icons.schedule;
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
          Icon(icon, size: 12, color: Colors.white),
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

  Widget _buildCategoryBadge(String categoryName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x1A000000)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        categoryName,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0A0A0A),
        ),
      ),
    );
  }

  Widget _buildImagesSection(List<Map<String, dynamic>> soportes) {
    final images = soportes
        .where((s) => (s['tipo'] as String? ?? '') == 'imagen')
        .toList();

    if (images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Imágenes de la campaña',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length > 2 ? 2 : images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                return Container(
                  width: 166,
                  height: 128,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_outlined,
                        size: 40, color: Color(0xFF9CA3AF)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(height: 1, color: Color(0x1A000000)),
    );
  }

  Widget _buildDescriptionSection(String descripcion) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5565),
              height: 1.43,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(CampaignEntity c) {
    final organizador = '${c.creadorNombre} ${c.creadorApellido}'.trim();
    final meta = _formatCurrency(c.metaMonetaria);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Organizador:', organizador.isNotEmpty ? organizador : 'Desconocido'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem('Contacto:', c.creadorCorreo.isNotEmpty ? c.creadorCorreo : '—'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Ciudad:', c.ciudadNombre.isNotEmpty ? c.ciudadNombre : '—'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem('Meta:', meta),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF4A5565),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0A0A0A),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenciasSection(List<Map<String, dynamic>> soportes) {
    final evidencias = soportes
        .where((s) => (s['tipo'] as String? ?? '') != 'imagen')
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 16, color: Color(0xFF0A0A0A)),
              const SizedBox(width: 8),
              Text(
                'Evidencias (${soportes.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A0A0A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...evidencias.map((s) => _buildEvidenceItem(s)),
        ],
      ),
    );
  }

  Widget _buildEvidenceItem(Map<String, dynamic> soporte) {
    final name = soporte['descripcion'] as String? ?? 'Documento';
    final tipo = soporte['tipo'] as String? ?? 'documento';
    final tipoLabel = _mapTipoLabel(tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.description_outlined,
                  size: 20, color: Color(0xFF155DFC)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tipoLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A5565),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationHistory(CampaignEntity c) {
    final auditor =
        '${c.auditorNombre ?? ''} ${c.auditorApellido ?? ''}'.trim();
    final fecha = _formatDateTime(c.fechaRevision);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history,
                  size: 16, color: Color(0xFF0A0A0A)),
              const SizedBox(width: 8),
              const Text(
                'Historial de Verificación',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A0A0A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      auditor.isNotEmpty ? auditor : 'Auditor',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6900),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Alta',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (fecha.isNotEmpty)
                  Text(
                    fecha,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4A5565),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.close,
                        size: 16, color: Color(0xFFE7000B)),
                    const SizedBox(width: 8),
                    const Text(
                      'rechazada',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (c.notaRevision != null && c.notaRevision!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      c.notaRevision!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF364153),
                        height: 1.43,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionPointsSection(
      List<Map<String, dynamic>> puntosRecoleccion) {
    if (puntosRecoleccion.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Color(0xFF0A0A0A)),
              const SizedBox(width: 8),
              Text(
                'Puntos de Recolección (${puntosRecoleccion.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A0A0A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...puntosRecoleccion.map((p) => _buildCollectionPointItem(p)),
        ],
      ),
    );
  }

  Widget _buildCollectionPointItem(Map<String, dynamic> punto) {
    final name = punto['nombre'] as String? ?? 'Punto';
    final direccion = punto['direccion'] as String? ?? '';
    final horario = punto['horario'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0A0A0A),
            ),
          ),
          if (direccion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              direccion,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4A5565),
              ),
            ),
          ],
          if (horario.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              horario,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4A5565),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0x1A000000), width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 36,
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
            onPressed: () async {
              final c = controller.campaignDetail.value;
              if (c == null) return;
              await SupportEvaluationDialog.show(_id, c.titulo);
              Get.offAllNamed(AppRoutes.supportHome);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Evaluar campaña',
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
    );
  }

  Widget _buildBottomPadding() {
    return const SizedBox(height: 100);
  }

  String _mapTipoLabel(String tipo) {
    switch (tipo) {
      case 'documento_oficial':
        return 'Documento';
      case 'imagen':
        return 'Imagen';
      case 'video':
        return 'Video';
      case 'enlace':
        return 'Enlace';
      case 'institucional':
        return 'Institucional';
      default:
        return 'Documento';
    }
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final result = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(parts[i]);
    }
    return '\$$result';
  }

  String _formatDateTime(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      final day = date.day;
      final month = date.month;
      final year = date.year;
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final amPm = hour >= 12 ? 'p. m.' : 'a. m.';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$day/$month/$year, $hour12:$minute $amPm';
    } catch (_) {
      return isoDate;
    }
  }
}
