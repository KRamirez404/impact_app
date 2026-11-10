import 'package:flutter/material.dart';

class DocsTab extends StatelessWidget {
  final List<Map<String, dynamic>> supports;
  final Map<String, dynamic>? financialReport;
  final VoidCallback? onUploadFinancialReport;
  final bool canUploadFinancialReport;

  const DocsTab({
    super.key,
    required this.supports,
    this.financialReport,
    this.onUploadFinancialReport,
    this.canUploadFinancialReport = false,
  });

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
    final hasFinancial = financialReport != null;
    final isEmpty = supports.isEmpty && !hasFinancial;

    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Sin documentos ni informe financiero',
                style: TextStyle(fontSize: 16, color: Color(0xFF717182)),
              ),
              if (canUploadFinancialReport && onUploadFinancialReport != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onUploadFinancialReport,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Cargar informe financiero'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (canUploadFinancialReport && onUploadFinancialReport != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: onUploadFinancialReport,
              icon: const Icon(Icons.upload_file),
              label: Text(
                hasFinancial
                    ? 'Actualizar informe financiero'
                    : 'Cargar informe financiero (PDF / DOCX)',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
        if (hasFinancial) ...[
          _FinancialReportCard(report: financialReport!),
          if (supports.isNotEmpty) const SizedBox(height: 12),
        ],
        ...supports.map((support) {
          final tipo = (support['tipo'] ?? '').toString();
          final descripcion = (support['descripcion'] ?? '').toString();
          final url = (support['url_o_ruta'] ?? '').toString();
          final validado = support['validado'] == true;
          final title =
              descripcion.isNotEmpty ? descripcion : (url.isNotEmpty ? url : 'Documento');
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SupportCard(
              icon: _typeIcon(tipo),
              title: title,
              subtitle: _typeLabel(tipo),
              isVerified: validado,
            ),
          );
        }),
      ],
    );
  }
}

class _FinancialReportCard extends StatelessWidget {
  const _FinancialReportCard({required this.report});

  final Map<String, dynamic> report;

  @override
  Widget build(BuildContext context) {
    final fileName = (report['nombre_archivo'] ?? 'Informe financiero').toString();
    final mime = (report['mime_type'] ?? 'Documento').toString();
    final isPdf = mime.contains('pdf') || fileName.toLowerCase().endsWith('.pdf');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPdf ? Icons.picture_as_pdf_outlined : Icons.description_outlined,
                    size: 24,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informe Financiero de Campaña',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fileName,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 12, color: Color(0xFF008236)),
                SizedBox(width: 4),
                Text(
                  'Disponible',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF008236),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
