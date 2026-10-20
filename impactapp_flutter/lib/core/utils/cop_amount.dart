import 'dart:math';

const int minDonationCents = 100000;
const int maxDonationCents = 999999999999;

class CopAmountParseResult {
  const CopAmountParseResult.valid(int value) : cents = value, error = null;

  const CopAmountParseResult.invalid(String message)
    : cents = null,
      error = message;

  final int? cents;
  final String? error;

  bool get isValid => cents != null;
}

CopAmountParseResult parseCopAmount(String raw) {
  final clean = raw.replaceAll(RegExp(r'[\s$]'), '');
  if (clean.isEmpty) {
    return const CopAmountParseResult.invalid('Ingresa un monto válido');
  }
  if (!RegExp(r'^[0-9.,]+$').hasMatch(clean)) {
    return const CopAmountParseResult.invalid('Ingresa un monto válido');
  }

  String normalized;
  if (clean.contains(',')) {
    if (','.allMatches(clean).length != 1) {
      return const CopAmountParseResult.invalid('Ingresa un monto válido');
    }
    final partes = clean.split(',');
    final entero = partes[0];
    final decimales = partes[1];
    final enteroValido = entero.contains('.')
        ? RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(entero)
        : RegExp(r'^\d+$').hasMatch(entero);
    if (!enteroValido || !RegExp(r'^\d{1,2}$').hasMatch(decimales)) {
      return const CopAmountParseResult.invalid(
        'Usa como máximo dos decimales',
      );
    }
    normalized = '${entero.replaceAll('.', '')}.$decimales';
  } else if (clean.contains('.')) {
    final partes = clean.split('.');
    if (partes.length > 2) {
      if (!RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(clean)) {
        return const CopAmountParseResult.invalid('Ingresa un monto válido');
      }
      normalized = '${clean.replaceAll('.', '')}.00';
    } else {
      final entero = partes[0];
      final decimales = partes[1];
      if (!RegExp(r'^\d+$').hasMatch(entero) ||
          !RegExp(r'^\d+$').hasMatch(decimales)) {
        return const CopAmountParseResult.invalid('Ingresa un monto válido');
      }
      final cero = int.tryParse(entero) == 0;
      if (decimales.length == 3 && !cero && entero.length <= 3) {
        normalized = '$entero$decimales.00';
      } else if (decimales.isNotEmpty && decimales.length <= 2) {
        normalized = '$entero.$decimales';
      } else {
        return const CopAmountParseResult.invalid(
          'Usa como máximo dos decimales',
        );
      }
    }
  } else {
    if (!RegExp(r'^\d+$').hasMatch(clean)) {
      return const CopAmountParseResult.invalid('Ingresa un monto válido');
    }
    normalized = '$clean.00';
  }

  final partes = normalized.split('.');
  if (partes.length != 2 ||
      !RegExp(r'^\d+$').hasMatch(partes[0]) ||
      !RegExp(r'^\d{1,2}$').hasMatch(partes[1])) {
    return const CopAmountParseResult.invalid('Ingresa un monto válido');
  }
  final enteros = int.tryParse(partes[0]);
  final decimales = int.parse(partes[1].padRight(2, '0'));
  if (enteros == null) {
    return const CopAmountParseResult.invalid('Ingresa un monto válido');
  }
  final cents = enteros * 100 + decimales;
  if (cents < minDonationCents) {
    return const CopAmountParseResult.invalid(
      'El monto mínimo de donación es 1.000 COP',
    );
  }
  if (cents > maxDonationCents) {
    return const CopAmountParseResult.invalid(
      'El monto supera el máximo permitido',
    );
  }
  return CopAmountParseResult.valid(cents);
}

String formatCopAmountForApi(int cents) {
  final enteros = cents ~/ 100;
  final decimales = (cents % 100).toString().padLeft(2, '0');
  return '$enteros.$decimales';
}

String formatCopAmount(int cents) {
  final enteros = cents ~/ 100;
  final decimales = cents % 100;
  final agrupado = enteros.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match[1]}.',
  );
  if (decimales == 0) {
    return '\$$agrupado';
  }
  return '\$$agrupado,${decimales.toString().padLeft(2, '0')}';
}

String newIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return 'impactapp-${DateTime.now().toUtc().microsecondsSinceEpoch}-$hex';
}
