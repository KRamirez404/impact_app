import 'package:flutter/material.dart';

class CollectionPointDraft {
  const CollectionPointDraft({
    required this.nombre,
    required this.direccion,
    required this.horario,
    required this.articulosAceptados,
  });

  final String nombre;
  final String direccion;
  final String horario;
  final String articulosAceptados;

  Map<String, String> toMap() => {
    'nombre': nombre,
    'direccion': direccion,
    'horario': horario,
    'articulos_aceptados': articulosAceptados,
  };
}

class CreateCollectionPointModal extends StatefulWidget {
  const CreateCollectionPointModal({super.key});

  @override
  State<CreateCollectionPointModal> createState() =>
      _CreateCollectionPointModalState();
}

class _CreateCollectionPointModalState
    extends State<CreateCollectionPointModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _horarioCtrl = TextEditingController();
  final _articulosCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _horarioCtrl.dispose();
    _articulosCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintMaxLines: 1,
      filled: true,
      fillColor: const Color(0xFFF3F3F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        height: 1.19,
        color: Color(0xFF717182),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.33,
            color: Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: _decoration(hint),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            height: 1.19,
            color: Color(0xFF0A0A0A),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label es obligatorio';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final dialogMaxWidth = mq.size.width * 0.92;
    final dialogMaxHeight = mq.size.height * 0.9;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogMaxWidth,
            maxHeight: dialogMaxHeight,
          ),
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.black.withOpacity(0.1),
                  width: 1.18025,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Puntos de Recolección (Opcional)',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                                color: Color(0xFF0A0A0A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ubicaciones para donaciones físicas',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                height: 1.33,
                                color: Color(0xFF717182),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(13, 13, 13, 1),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black.withOpacity(0.1),
                              width: 1.18025,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              _field(
                                label: 'Nombre del lugar',
                                controller: _nombreCtrl,
                                hint: 'Ej: Centro Comunitario',
                              ),
                              const SizedBox(height: 12),
                              _field(
                                label: 'Dirección',
                                controller: _direccionCtrl,
                                hint: 'Calle 10 #20-30',
                              ),
                              const SizedBox(height: 12),
                              _field(
                                label: 'Horario',
                                controller: _horarioCtrl,
                                hint: 'Lunes a Viernes 9:00 AM - 5:00 PM',
                              ),
                              const SizedBox(height: 12),
                              _field(
                                label: 'Artículos aceptados',
                                controller: _articulosCtrl,
                                hint: 'Ej: Alimentos, ropa...',
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (!_formKey.currentState!.validate()) {
                                          return;
                                        }
                                        Navigator.of(context).pop(
                                          CollectionPointDraft(
                                            nombre: _nombreCtrl.text.trim(),
                                            direccion: _direccionCtrl.text
                                                .trim(),
                                            horario: _horarioCtrl.text.trim(),
                                            articulosAceptados: _articulosCtrl
                                                .text
                                                .trim(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1976D2,
                                        ),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(32),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Agregar',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          height: 1.43,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(32),
                                        side: BorderSide(
                                          color: Colors.black.withOpacity(0.1),
                                          width: 1.18025,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        foregroundColor: const Color(
                                          0xFF0A0A0A,
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancelar',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          height: 1.43,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
