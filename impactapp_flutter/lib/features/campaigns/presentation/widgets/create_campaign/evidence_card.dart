import 'package:flutter/material.dart';
import 'campaign_card_wrapper.dart';

class EvidenceCard extends StatelessWidget {
  const EvidenceCard({
    super.key,
    required this.attachmentsCount,
    required this.onPickAttachments,
  });

  final int attachmentsCount;
  final VoidCallback onPickAttachments;

  @override
  Widget build(BuildContext context) {
    return CampaignCardWrapper(
      title: 'Evidencias y Documentos',
      description: 'Adjunta documentos que respalden tu campaña',
      height: 274.77,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.8, 24.79, 24.8, 24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 163.19,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black.withOpacity(0.1), width: 1.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_outlined, size: 40, color: Color(0xFF717182)),
                  const SizedBox(height: 16),
                  const Text(
                    'Documentos oficiales, fotos, enlaces a medios',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.33, color: Color(0xFF717182)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: onPickAttachments,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(153.6, 32),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black.withOpacity(0.1), width: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      foregroundColor: const Color(0xFF0A0A0A),
                    ),
                    child: const Text(
                      'Seleccionar archivos',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
                    ),
                  ),
                ],
              ),
            ),
            if (attachmentsCount > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$attachmentsCount archivo(s) seleccionado(s)',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF717182)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
