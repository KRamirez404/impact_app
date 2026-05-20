import 'package:flutter/material.dart';

class InfoTab extends StatelessWidget {
  final dynamic campaign;

  const InfoTab({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final organizer = [
      campaign.creadorNombre,
      campaign.creadorApellido,
    ].where((e) => e.toString().isNotEmpty).join(' ');

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _SectionBlock(
          title: 'Descripción',
          child: Text(
            campaign.descripcion,
            style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF717182)),
          ),
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: 'Organizador',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                organizer.isNotEmpty ? organizer : 'Sin datos',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                campaign.creadorCorreo.isNotEmpty ? campaign.creadorCorreo : 'Sin correo',
                style: const TextStyle(fontSize: 14, color: Color(0xFF717182)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: 'Puntos de Recolección',
          child: campaign.puntosRecoleccion.isEmpty
              ? const Text('No hay puntos registrados', style: TextStyle(color: Color(0xFF717182)))
              : Column(
                  children: campaign.puntosRecoleccion.map<Widget>((point) {
                    final horario = point['horario'] ?? '';
                    final direccion = point['direccion'] ?? '';
                    final ciudad = point['ciudad']?['nombre'] ?? '';
                    final contacto = point['contacto'] ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (point['nombre'] ?? '').toString(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            text: '$direccion ${ciudad.toString().isEmpty ? '' : '- $ciudad'}',
                          ),
                          if (horario.toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _InfoRow(icon: Icons.schedule, text: horario.toString()),
                          ],
                          if (contacto.toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _InfoRow(icon: Icons.phone_outlined, text: contacto.toString()),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF717182)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF717182))),
        ),
      ],
    );
  }
}
