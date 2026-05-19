import 'package:flutter/material.dart';
import '../../features/campaigns/domain/entities/campaign_entity.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({
    super.key,
    required this.campaign,
    required this.onTap,
  });

  final CampaignEntity campaign;
  final VoidCallback onTap;

  Color _categoryBadgeColor(String nombre) {
    switch (nombre.toLowerCase()) {
      case 'desastres naturales':
        return const Color(0xFFFFEDD4);
      case 'salud':
        return const Color(0xFFDCFCE7);
      case 'educación':
        return const Color(0xFFDBEAFE);
      case 'pobreza estructural':
        return const Color(0xFFF3E8FF);
      case 'desplazamiento forzado':
        return const Color(0xFFFFE4E6);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _categoryTextColor(String nombre) {
    switch (nombre.toLowerCase()) {
      case 'desastres naturales':
        return const Color(0xFFCA3500);
      case 'salud':
        return const Color(0xFF008236);
      case 'educación':
        return const Color(0xFF1E56A0);
      case 'pobreza estructural':
        return const Color(0xFF6B21A8);
      case 'desplazamiento forzado':
        return const Color(0xFFBE123C);
      default:
        return const Color(0xFF364153);
    }
  }

  Color _categoryColor(String nombre) {
    switch (nombre.toLowerCase()) {
      case 'desastres naturales':
        return const Color(0xFFF97316);
      case 'salud':
        return const Color(0xFF22C55E);
      case 'educación':
        return const Color(0xFF3B82F6);
      case 'pobreza estructural':
        return const Color(0xFFA855F7);
      case 'desplazamiento forzado':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = campaign.porcentajeAvance >= 100;
    final isVerificada = campaign.estado == 'activa' || campaign.estado == 'finalizada';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(isCompleted, isVerificada),
            _buildContentSection(isCompleted),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isCompleted, bool isVerificada) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: Container(
        height: 192,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _categoryColor(campaign.categoriaNombre).withValues(alpha: 0.7),
              _categoryColor(campaign.categoriaNombre),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            if (isCompleted)
              Container(
                color: const Color(0x6643A047),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 20, color: Color(0xFF364153)),
                        SizedBox(width: 8),
                        Text('Meta Alcanzada',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF364153))),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _categoryBadgeColor(campaign.categoriaNombre),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  campaign.categoriaNombre,
                  style: TextStyle(
                    fontSize: 12,
                    color: _categoryTextColor(campaign.categoriaNombre),
                  ),
                ),
              ),
            ),
            if (isVerificada)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A63E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Verificada',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(bool isCompleted) {
    final amountRaised = campaign.metaMonetaria * campaign.porcentajeAvance / 100;
    final amountGoal = campaign.metaMonetaria;
    final progress = (campaign.porcentajeAvance / 100).clamp(0, 1).toDouble();
    final daysLeft = _daysRemaining(campaign.fechaFin);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campaign.titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              color: isCompleted ? const Color(0xFF717182) : const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            campaign.descripcion,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.43,
              color: Color(0xFF717182),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoRow(Icons.location_on_outlined, campaign.ciudadNombre),
              const SizedBox(width: 16),
              _infoRow(Icons.people_outline, '${campaign.donantesCount} donantes'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatCurrency(amountRaised),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1976D2),
                ),
              ),
              Text(
                'de ${_formatCurrency(amountGoal)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF717182),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF1976D2).withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${campaign.porcentajeAvance.toStringAsFixed(0)}% alcanzado',
                style: const TextStyle(fontSize: 12, color: Color(0xFF717182)),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: Color(0xFF717182)),
                  const SizedBox(width: 4),
                  Text(
                    '$daysLeft días restantes',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF717182)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final puntos = campaign.puntosCount;
    final puntosText = puntos == 1 ? 'punto' : 'puntos';
    final dispText = puntos == 1 ? 'disponible' : 'disponibles';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x1A000000), width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$puntos $puntosText de recolección $dispText',
            style: const TextStyle(fontSize: 12, color: Color(0xFF717182)),
          ),
          Text(
            '${campaign.vistasCount} Visualizaciones',
            style: const TextStyle(fontSize: 12, color: Color(0xFF717182)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF717182)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF717182))),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      final millones = (amount / 1000000).toStringAsFixed(1);
      return '\$${millones.replaceAll('.', ',')}M';
    } else if (amount >= 1000) {
      final miles = (amount / 1000).toStringAsFixed(0);
      return '\$$miles.000';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  int _daysRemaining(String fechaFin) {
    try {
      final fin = DateTime.parse(fechaFin);
      final diff = fin.difference(DateTime.now()).inDays;
      return diff < 0 ? 0 : diff;
    } catch (_) {
      return 0;
    }
  }
}
