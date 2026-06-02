import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/support_controller.dart';

enum EvaluationAction { approve, requestInfo, reject }

class SupportEvaluationDialog {
  static Future<EvaluationAction?> show(
    int campaignId,
    String titulo,
  ) {
    return Get.dialog<EvaluationAction>(
      _EvaluationDialogContent(campaignId: campaignId, titulo: titulo),
      barrierDismissible: false,
    );
  }
}

class _EvaluationDialogContent extends StatefulWidget {
  final int campaignId;
  final String titulo;

  const _EvaluationDialogContent({
    required this.campaignId,
    required this.titulo,
  });

  @override
  State<_EvaluationDialogContent> createState() =>
      _EvaluationDialogContentState();
}

class _EvaluationDialogContentState extends State<_EvaluationDialogContent> {
  final _noteController = TextEditingController();
  EvaluationAction? _selectedAction;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SupportController>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0x1A000000), width: 1.18),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      child: Container(
        width: 373,
        padding: const EdgeInsets.all(25),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildActionSection(),
            const SizedBox(height: 16),
            _buildNotesSection(),
            const SizedBox(height: 20),
            _buildFooter(controller),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Verificar Campaña',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A0A0A),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.titulo,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF717182),
                  height: 1.43,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Get.back(),
          child: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.close, size: 16, color: Color(0xB30A0A0A)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acción de verificación',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 12),
        _buildRadioOption(
          action: EvaluationAction.approve,
          icon: Icons.check,
          iconColor: const Color(0xFF00A63E),
          label: 'Aprobar campaña',
        ),
        const SizedBox(height: 4),
        _buildRadioOption(
          action: EvaluationAction.requestInfo,
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFF54900),
          label: 'Requiere más información',
        ),
        const SizedBox(height: 4),
        _buildRadioOption(
          action: EvaluationAction.reject,
          icon: Icons.close,
          iconColor: const Color(0xFFE7000B),
          label: 'Rechazar campaña',
        ),
      ],
    );
  }

  Widget _buildRadioOption({
    required EvaluationAction action,
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    final isSelected = _selectedAction == action;
    return GestureDetector(
      onTap: () => setState(() => _selectedAction = action),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF7C7C7C)
                  : const Color(0x3D7C7C7C),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.52),
                  blurRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0A0A0A),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notas (opcional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF0A0A0A),
            ),
            decoration: const InputDecoration(
              hintText: 'Agregar comentarios sobre la aprobación...',
              hintStyle: TextStyle(color: Color(0xFF717182)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(SupportController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 36,
          child: ElevatedButton(
            onPressed: _selectedAction == null
                ? null
                : () => _onConfirm(controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return const Color(0xFFB0B0B0);
                }
                return null;
              }),
            ),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: _selectedAction != null
                    ? const LinearGradient(
                        colors: [Color(0xFF155DFC), Color(0xFF00A63E)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: _selectedAction == null
                    ? const Color(0xFFB0B0B0)
                    : null,
              ),
              child: Container(
                alignment: Alignment.center,
                child: const Text(
                  'Confirmar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0A0A0A),
              side: const BorderSide(color: Color(0x1A000000)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onConfirm(SupportController controller) async {
    if (_selectedAction == null) return;

    final note = _noteController.text.trim();
    if (_selectedAction == EvaluationAction.reject && note.isEmpty) {
      Get.snackbar(
        'Error',
        'La nota de rechazo es obligatoria',
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
      return;
    }

    Get.back();

    switch (_selectedAction!) {
      case EvaluationAction.approve:
        await controller.approve(widget.campaignId);
        break;
      case EvaluationAction.requestInfo:
        final fullNote =
            '[Requiere más información]${note.isNotEmpty ? ' - $note' : ''}';
        await controller.reject(widget.campaignId, fullNote);
        break;
      case EvaluationAction.reject:
        await controller.reject(widget.campaignId, note);
        break;
    }
  }
}
