import '../../domain/entities/receipt_entity.dart';

class ReceiptModel extends ReceiptEntity {
  const ReceiptModel({
    required super.idComprobante,
    required super.idTransferencia,
    required super.version,
    required super.mime,
    required super.tamanoBytes,
    required super.estadoTecnico,
    required super.creadoEn,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      idComprobante: (json['id_comprobante'] as num).toInt(),
      idTransferencia: (json['id_transferencia'] as num).toInt(),
      version: (json['version'] as num).toInt(),
      mime: json['mime']?.toString() ?? '',
      tamanoBytes: (json['tamano_bytes'] as num).toInt(),
      estadoTecnico: json['estado_tecnico']?.toString() ?? '',
      creadoEn: json['creado_en']?.toString() ?? '',
    );
  }
}
