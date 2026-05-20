import 'package:flutter/material.dart';

class TrackingTab extends StatelessWidget {
  final List<Map<String, dynamic>> tracking;
  final String Function(String) formatDate;

  const TrackingTab({
    super.key,
    required this.tracking,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    if (tracking.isEmpty) {
      return const Center(child: Text('Sin avances registrados'));
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: tracking.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final item = tracking[index];
        final fecha = item['fecha_registro'] ?? '';
        final descripcion = item['descripcion'] ?? '';
        final avance = item['porcentaje_avance'] ?? '';
        return _SimpleCard(
          title: '${formatDate(fecha.toString())} • $avance%',
          subtitle: descripcion.toString(),
        );
      },
    );
  }
}

class _SimpleCard extends StatelessWidget {
  const _SimpleCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

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
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF717182))),
        ],
      ),
    );
  }
}
