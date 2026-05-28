import 'package:flutter/material.dart';
import 'campaign_card_wrapper.dart';

class OrganizerCard extends StatelessWidget {
  const OrganizerCard({
    super.key,
    required this.cuentaCtrl,
    required this.correoCtrl,
  });

  final TextEditingController cuentaCtrl;
  final TextEditingController correoCtrl;

  @override
  Widget build(BuildContext context) {
    return CampaignCardWrapper(
      title: 'Información del Organizador',
      description: 'Datos de contacto del responsable',
      height: 243.59,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Inserte número de Cuenta o Bre-B'),
            const SizedBox(height: 4),
            TextFormField(
              controller: cuentaCtrl,
              decoration: _inputDecoration('Ej: @tucuenta123'),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            _label('Correo de contacto *'),
            const SizedBox(height: 4),
            TextFormField(
              controller: correoCtrl,
              decoration: _inputDecoration('Ej: contacto@campana.org'),
              maxLines: 1,
              validator: (v) => v == null || v.trim().isEmpty ? 'Correo es obligatorio' : null,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintMaxLines: 1,
      hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, height: 1.19, color: Color(0xFF717182)),
      filled: true,
      fillColor: const Color(0xFFF3F3F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.43, color: Color(0xFF0A0A0A)),
    );
  }
}
