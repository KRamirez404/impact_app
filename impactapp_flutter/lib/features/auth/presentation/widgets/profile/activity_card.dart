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
                          onPressed: () => Get.toNamed(
                            AppRoutes.supportCampaignDetail,
                            parameters: {'id': item.campaignId.toString()},
                          ),
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
