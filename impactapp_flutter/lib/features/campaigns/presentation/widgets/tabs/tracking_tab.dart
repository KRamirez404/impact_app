import 'package:flutter/material.dart';

class TrackingTab extends StatelessWidget {
  final List<Map<String, dynamic>> tracking;
  final String Function(String) formatDate;

  const TrackingTab({
    super.key,
    required this.tracking,
    required this.formatDate,
  });

  String _headlineForProgress(double progress) {
    if (progress >= 90) {
      return '¡Meta casi alcanzada!';
    }
    if (progress >= 75) {
      return '¡Gran avance!';
    }
    if (progress >= 50) {
      return '¡Seguimos avanzando!';
    }
    if (progress >= 25) {
      return 'Primeros avances';
    }
    return 'Actualización de campaña';
  }

  @override
  Widget build(BuildContext context) {
    if (tracking.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Sin avances registrados',
              style: TextStyle(fontSize: 16, color: Color(0xFF717182)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: tracking.length,
      separatorBuilder: (_, index) => const SizedBox(height: 16),
      itemBuilder: (_, index) {
        final item = tracking[index];
        final fecha = item['fecha_registro'] ?? '';
        final descripcion = item['descripcion'] ?? '';
        final avance = (item['porcentaje_avance'] as num?)?.toDouble() ?? 0;
        final evidenciaUrl = (item['evidencia_url'] ?? '').toString().trim();
        return _TrackingCard(
          date: formatDate(fecha.toString()),
          title: _headlineForProgress(avance),
          description: descripcion.toString(),
          evidenceUrl: evidenciaUrl.isEmpty ? null : evidenciaUrl,
        );
      },
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({
    required this.date,
    required this.title,
    required this.description,
    required this.evidenceUrl,
  });

  final String date;
  final String title;
  final String description;
  final String? evidenceUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF717182)),
              const SizedBox(width: 8),
              Text(
                date,
                style: const TextStyle(fontSize: 14, color: Color(0xFF717182)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF717182)),
          ),
          if (evidenceUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 128,
                width: double.infinity,
                child: Image.network(
                  evidenceUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF3F3F5),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF717182),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
