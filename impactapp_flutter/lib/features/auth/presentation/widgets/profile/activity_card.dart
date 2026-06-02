import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../app/routes/app_routes.dart';
import 'activity_item.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.item});

  final ProfileActivityItem item;

  Color _badgeBg() {
    if (item.status == 'Finalizada') return const Color(0xFFF0FDF4);
    if (item.status == 'Activa') return const Color(0xFFE0F2FE);
    if (item.status == 'En verificación') return const Color(0xFFFFF7ED);
    if (item.status == 'Rechazada') return const Color(0xFFFB2C36);
    return const Color(0xFFF1F5F9);
  }

  Color _badgeBorder() {
    if (item.status == 'Finalizada') return const Color(0xFFB9F8CF);
    if (item.status == 'Activa') return const Color(0xFFBAE6FD);
    if (item.status == 'En verificación') return const Color(0xFFFED7AA);
    if (item.status == 'Rechazada') return const Color(0xFFFB2C36);
    return const Color(0xFFE2E8F0);
  }

  Color _badgeText() {
    if (item.status == 'Finalizada') return const Color(0xFF008236);
    if (item.status == 'Activa') return const Color(0xFF0369A1);
    if (item.status == 'En verificación') return const Color(0xFFC2410C);
    if (item.status == 'Rechazada') return Colors.white;
    return const Color(0xFF334155);
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = item.status == 'Rechazada';
    final canNavigate = item.campaignId != null && !isRejected;
    final note = item.rejectionNote?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final auditor = item.auditorName?.trim();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: canNavigate
            ? () => Get.toNamed(
                  AppRoutes.donors,
                  parameters: {'id': item.campaignId.toString(), 'title': item.title},
                )
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                      style: const TextStyle(
                        fontSize: 18, color: Color(0xFF43A047), fontWeight: FontWeight.w600,
                      ),
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
                          child: item.status == 'Rechazada'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.close, size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.status,
                                      style: TextStyle(
                                        fontSize: 12, color: _badgeText(), fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  item.status,
                                  style: TextStyle(
                                    fontSize: 12, color: _badgeText(), fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    if (isRejected && hasNote) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF97316)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                auditor == null || auditor.isEmpty
                                    ? 'Última nota: $note'
                                    : 'Última nota - Auditor: $auditor. $note',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9A3412),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isRejected && item.campaignId != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectionDetails(context),
                          icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                          label: const Text('Ver detalles'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0A0A0A),
                            side: const BorderSide(color: Color(0x1A000000)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cancel, color: Color(0xFFDC2626), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Rechazada',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFF717182)),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A0A0A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0x1A000000)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'META DE RECAUDACIÓN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF717182),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(item.amount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FECHA LÍMITE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF717182),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.date,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'NOTAS DE REVISIÓN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF717182),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.rate_review_outlined,
                            size: 16,
                            color: Color(0xFFF97316),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.auditorName ?? 'Verificador / Auditor',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.rejectionNote ?? 'No se especificaron notas detalladas para el rechazo.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7C2D12),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
