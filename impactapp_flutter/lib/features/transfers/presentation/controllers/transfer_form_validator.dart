class TransferFormResult {
  final String? error;
  final String? amountForApi;
  final String? reference;
  final String? dateForApi;

  const TransferFormResult({
    this.error,
    this.amountForApi,
    this.reference,
    this.dateForApi,
  });
}

abstract class TransferFormValidator {
  static TransferFormResult validate({
    required String amount,
    required String reference,
    required DateTime transferDate,
    DateTime? today,
  }) {
    final normalizedAmount = amount.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalizedAmount)) {
      return const TransferFormResult(
        error: 'El monto admite máximo dos decimales',
      );
    }
    final parsed = double.tryParse(normalizedAmount);
    if (parsed == null || parsed < 1000) {
      return const TransferFormResult(error: 'El monto mínimo es 1.000 COP');
    }
    final normalizedReference = reference.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (normalizedReference.isEmpty || normalizedReference.length > 100) {
      return const TransferFormResult(error: 'Referencia bancaria inválida');
    }
    final current = today ?? DateTime.now();
    final dateOnly = DateTime(
      transferDate.year,
      transferDate.month,
      transferDate.day,
    );
    final currentOnly = DateTime(current.year, current.month, current.day);
    if (dateOnly.isAfter(currentOnly)) {
      return const TransferFormResult(error: 'La fecha no puede ser futura');
    }
    final amountParts = normalizedAmount.split('.');
    final amountForApi = amountParts.length == 1
        ? '${amountParts.first}.00'
        : '${amountParts.first}.${amountParts.last.padRight(2, '0')}';
    final date =
        '${dateOnly.year.toString().padLeft(4, '0')}-'
        '${dateOnly.month.toString().padLeft(2, '0')}-'
        '${dateOnly.day.toString().padLeft(2, '0')}';
    return TransferFormResult(
      amountForApi: amountForApi,
      reference: normalizedReference,
      dateForApi: date,
    );
  }
}
