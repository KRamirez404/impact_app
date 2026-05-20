import 'package:flutter/material.dart';

class DocsTab extends StatelessWidget {
  final List<Map<String, dynamic>> supports;

  const DocsTab({super.key, required this.supports});

  String _typeLabel(String rawType) {
    switch (rawType.toLowerCase()) {
      case 'documento_oficial':
        return 'documento';
      case 'imagen':
        return 'imagen';
      case 'enlace_medio':
        return 'enlace';
      case 'certificado_institucional':
        return 'institucional';
      default:
        return 'documento';
    }
  }

  IconData _typeIcon(String rawType) {
    switch (rawType.toLowerCase()) {
      case 'imagen':
        return Icons.photo_outlined;
      case 'enlace_medio':
        return Icons.link;
      case 'certificado_institucional':
        return Icons.verified_outlined;
      case 'documento_oficial':
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (supports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Sin documentos',
              style: TextStyle(fontSize: 16, color: Color(0xFF717182)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: supports.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final support = supports[index];
        final tipo = (support['tipo'] ?? '').toString();
        final descripcion = (support['descripcion'] ?? '').toString();
        final url = (support['url_o_ruta'] ?? '').toString();
        final validado = support['validado'] == true;
        final title =
            descripcion.isNotEmpty ? descripcion : (url.isNotEmpty ? url : 'Documento');
        return _SupportCard(
          icon: _typeIcon(tipo),
          title: title,
          subtitle: _typeLabel(tipo),
          isVerified: validado,
        );
      },
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isVerified,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, size: 20, color: const Color(0xFF1976D2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF717182)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, size: 12, color: Color(0xFF008236)),
                  SizedBox(width: 4),
                  Text(
                    'Verificado',
                    style: TextStyle(fontSize: 12, color: Color(0xFF008236)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
