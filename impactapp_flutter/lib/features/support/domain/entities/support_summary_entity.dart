class SupportSummaryEntity {
  final int pendientes;
  final int aprobadas;
  final int rechazadas;
  final int eliminadas;

  const SupportSummaryEntity({
    required this.pendientes,
    required this.aprobadas,
    required this.rechazadas,
    this.eliminadas = 0,
  });
}
