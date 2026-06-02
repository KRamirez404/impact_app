import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/network/dio_client.dart';

Future<void> showPhysicalDonationDialog({
  required BuildContext context,
  required int campaignId,
  required List<Map<String, dynamic>> puntosRecoleccion,
  required Future<void> Function(Map<String, dynamic>) onDonate,
}) async {
  final commentController = TextEditingController();
  final availableTypes = const [
    {'label': 'Alimentos', 'value': 'alimentos'},
    {'label': 'Medicamentos', 'value': 'medicamentos'},
    {'label': 'Ropa', 'value': 'ropa'},
    {'label': 'Otro', 'value': 'otros'},
  ];
  var selectedType = availableTypes.first['value']!;
  int? selectedPointId;
  if (puntosRecoleccion.isNotEmpty) {
    selectedPointId = puntosRecoleccion.first['id_punto'] as int?;
  }
  var isUploading = false;
  String? photoUrl;
  var isSaving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              width: 384,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.black.withOpacity(0.1),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 15,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Realizar Donación Físico',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Ingrese lo donado',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF717182)),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Selecciona Punto Físico',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedPointId,
                        isExpanded: true,
                        items: puntosRecoleccion
                            .map(
                              (point) => DropdownMenuItem<int>(
                                value: point['id_punto'] as int?,
                                child: Text(
                                  (point['nombre'] ?? '').toString(),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedPointId = value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Qué Donó',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        items: availableTypes
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item['value']!,
                                child: Text(
                                  item['label']!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(
                          () => selectedType = value ?? selectedType,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Añade un Comentario (opcional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Escribe aquí',
                      filled: true,
                      fillColor: const Color(0xFFF3F3F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Compártenos una imagen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: isUploading || isSaving ? null : () async {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(source: ImageSource.gallery);
                      if (file != null) {
                        setState(() => isUploading = true);
                        try {
                          final url = await DioClient.instance.uploadFile(file.path);
                          setState(() => photoUrl = url);
                        } catch (e) {
                          Get.snackbar('Error', 'No se pudo subir la imagen',
                              backgroundColor: const Color(0xFFD32F2F), colorText: Colors.white);
                        } finally {
                          setState(() => isUploading = false);
                        }
                      }
                    },
                    child: Container(
                      height: 65,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: photoUrl != null ? Colors.green.withOpacity(0.1) : const Color(0xFFF3F3F5),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: photoUrl != null ? Colors.green : Colors.transparent,
                        ),
                      ),
                      child: isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  photoUrl != null ? Icons.check_circle : Icons.photo_camera_outlined,
                                  color: photoUrl != null ? Colors.green : const Color(0xFF2A343D),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  photoUrl != null ? 'Foto subida' : 'Tomar Foto',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: photoUrl != null ? Colors.green : const Color(0xFF717182),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        if (selectedPointId == null) {
                          Get.snackbar(
                            'Punto requerido',
                            'Selecciona un punto de recolección',
                            backgroundColor: const Color(0xFFD32F2F),
                            colorText: Colors.white,
                          );
                          return;
                        }
                        setState(() => isSaving = true);
                        final navigator = Navigator.of(dialogContext);
                        final baseDesc = commentController.text.trim();
                        final finalDesc = baseDesc.isEmpty 
                            ? (photoUrl != null ? 'Foto: $photoUrl' : '') 
                            : baseDesc + (photoUrl != null ? '\nFoto: $photoUrl' : '');
                        await onDonate({
                          'id_campania': campaignId,
                          'id_punto': selectedPointId,
                          'tipo': selectedType,
                          'monto_estimado': 0,
                          'descripcion': finalDesc,
                        });
                        navigator.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Confirmar Donación',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          );
        },
      );
    },
  );
  commentController.dispose();
}
