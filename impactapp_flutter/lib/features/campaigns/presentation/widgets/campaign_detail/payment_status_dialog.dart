import 'dart:async';

import 'package:flutter/material.dart';

const Map<String, String> _statusLabels = {
  'pendiente': 'Pago pendiente',
  'aprobada': 'Pago aprobado',
  'rechazada': 'Pago rechazado',
  'error': 'Error en el pago',
  'anulada': 'Pago anulado',
};

const Map<String, String> _statusMessages = {
  'pendiente': 'Estamos confirmando tu pago con Wompi. Esto puede tardar unos segundos.',
  'aprobada': '¡Gracias! Tu donación fue confirmada correctamente.',
  'rechazada': 'El pago no fue aprobado. Puedes intentarlo nuevamente.',
  'error': 'Ocurrió un error procesando el pago. Intenta nuevamente.',
  'anulada': 'El pago fue anulado.',
};

const Map<String, IconData> _statusIcons = {
  'pendiente': Icons.hourglass_top,
  'aprobada': Icons.check_circle,
  'rechazada': Icons.cancel,
  'error': Icons.error,
  'anulada': Icons.block,
};

const Map<String, Color> _statusColors = {
  'pendiente': Color(0xFF1976D2),
  'aprobada': Color(0xFF00A63E),
  'rechazada': Color(0xFFD32F2F),
  'error': Color(0xFFD32F2F),
  'anulada': Color(0xFF717182),
};

Future<String> showPaymentStatusDialog({
  required BuildContext context,
  required int donationId,
  required Future<String> Function(int donationId) onCheckStatus,
}) async {
  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PaymentStatusDialog(
      donationId: donationId,
      onCheckStatus: onCheckStatus,
    ),
  );
  return result ?? 'pendiente';
}

class _PaymentStatusDialog extends StatefulWidget {
  const _PaymentStatusDialog({
    required this.donationId,
    required this.onCheckStatus,
  });

  final int donationId;
  final Future<String> Function(int donationId) onCheckStatus;

  @override
  State<_PaymentStatusDialog> createState() => _PaymentStatusDialogState();
}

class _PaymentStatusDialogState extends State<_PaymentStatusDialog> {
  static const int _maxAttempts = 20;
  static const Duration _interval = Duration(seconds: 4);

  Timer? _timer;
  String _status = 'pendiente';
  int _attempts = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) return;
    _timer?.cancel();
    setState(() => _checking = true);
    try {
      final status = await widget.onCheckStatus(widget.donationId);
      if (!mounted) return;
      setState(() => _status = status);
      if (status == 'pendiente' && _attempts < _maxAttempts) {
        _attempts++;
        _timer = Timer(_interval, _check);
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[_status] ?? const Color(0xFF1976D2);
    final isPending = _status == 'pendiente';
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcons[_status] ?? Icons.hourglass_top, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            _statusLabels[_status] ?? _status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessages[_status] ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF717182)),
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
      actions: [
        if (isPending)
          TextButton(
            onPressed: _checking ? null : _check,
            child: const Text('Actualizar'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_status),
          child: Text(isPending ? 'Continuar' : 'Cerrar'),
        ),
      ],
    );
  }
}
