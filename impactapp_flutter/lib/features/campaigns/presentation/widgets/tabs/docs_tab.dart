import 'package:flutter/material.dart';

class DocsTab extends StatelessWidget {
  final List<Map<String, dynamic>> supports;

  const DocsTab({super.key, required this.supports});

  @override
  Widget build(BuildContext context) {
    if (supports.isEmpty) {
      return const Center(child: Text('Sin documentos'));
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: supports.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final support = supports[index];
        return _SimpleCard(
          title: (support['tipo'] ?? 'Documento').toString(),
          subtitle: (support['descripcion'] ?? support['url_o_ruta'] ?? '').toString(),
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
