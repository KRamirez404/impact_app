import 'package:flutter/material.dart';
import 'campaign_card_wrapper.dart';
import '../../pages/create_collection_point_modal.dart';

class PointsCard extends StatelessWidget {
  const PointsCard({
    super.key,
    required this.draftPoints,
    required this.onAddPoint,
  });

  final List<CollectionPointDraft> draftPoints;
  final VoidCallback onAddPoint;

  @override
  Widget build(BuildContext context) {
    return CampaignCardWrapper(
      title: 'Puntos de Recolección (Opcional)',
      description: 'Ubicaciones para donaciones físicas',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.8, 24, 24.8, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton(
              onPressed: onAddPoint,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 32),
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.black.withOpacity(0.1), width: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                foregroundColor: const Color(0xFF0A0A0A),
              ),
              child: const Text(
                'Agregar punto de recolección',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
              ),
            ),
            if (draftPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...draftPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                    ),
                    child: Text(
                      '${point.nombre} · ${point.direccion}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF0A0A0A)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
