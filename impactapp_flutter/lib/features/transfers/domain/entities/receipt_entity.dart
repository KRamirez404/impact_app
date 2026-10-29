class ReceiptEntity {
  final int idComprobante;
  final int idTransferencia;
  final int version;
  final String mime;
  final int tamanoBytes;
  final String estadoTecnico;
  final String creadoEn;

  const ReceiptEntity({
    required this.idComprobante,
    required this.idTransferencia,
    required this.version,
    required this.mime,
    required this.tamanoBytes,
    required this.estadoTecnico,
    required this.creadoEn,
  });
}
