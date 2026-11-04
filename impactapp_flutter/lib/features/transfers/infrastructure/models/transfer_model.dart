import '../../domain/entities/transfer_entity.dart';
import 'bank_account_model.dart';
import 'receipt_model.dart';

class TransferModel extends TransferEntity {
  const TransferModel({
    required super.idTransferencia,
    required super.idDonacion,
    required super.idCampania,
    required super.idCuentaRecaudo,
    required super.monto,
    required super.moneda,
    required super.referenciaBancaria,
    required super.fechaTransferencia,
    required super.estado,
    required super.creadoEn,
    required super.actualizadoEn,
    required super.campaniaTitulo,
    required super.cuenta,
    super.descripcion,
    super.motivoRechazo,
    super.comprobante,
  });

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    final account = Map<String, dynamic>.from(json['cuenta'] as Map);
    final campaign = Map<String, dynamic>.from(json['campania'] as Map);
    final receipt = json['comprobante'];
    return TransferModel(
      idTransferencia: (json['id_transferencia'] as num).toInt(),
      idDonacion: (json['id_donacion'] as num).toInt(),
      idCampania: (json['id_campania'] as num).toInt(),
      idCuentaRecaudo: (json['id_cuenta_recaudo'] as num).toInt(),
      monto: double.parse(json['monto'].toString()),
      moneda: json['moneda']?.toString() ?? 'COP',
      referenciaBancaria: json['referencia_bancaria']?.toString() ?? '',
      fechaTransferencia: json['fecha_transferencia']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      estado: json['estado']?.toString() ?? 'registrada',
      motivoRechazo: json['motivo_rechazo']?.toString(),
      creadoEn: json['creado_en']?.toString() ?? '',
      actualizadoEn: json['actualizado_en']?.toString() ?? '',
      campaniaTitulo: campaign['titulo']?.toString() ?? 'Campaña',
      cuenta: BankAccountModel.fromJson(account),
      comprobante: receipt is Map
          ? ReceiptModel.fromJson(Map<String, dynamic>.from(receipt))
          : null,
    );
  }
}
