import 'bank_account_entity.dart';
import 'receipt_entity.dart';

class TransferEntity {
  final int idTransferencia;
  final int idDonacion;
  final int idCampania;
  final int idCuentaRecaudo;
  final double monto;
  final String moneda;
  final String referenciaBancaria;
  final String fechaTransferencia;
  final String? descripcion;
  final String estado;
  final String? motivoRechazo;
  final String creadoEn;
  final String actualizadoEn;
  final String campaniaTitulo;
  final BankAccountEntity cuenta;
  final ReceiptEntity? comprobante;

  const TransferEntity({
    required this.idTransferencia,
    required this.idDonacion,
    required this.idCampania,
    required this.idCuentaRecaudo,
    required this.monto,
    required this.moneda,
    required this.referenciaBancaria,
    required this.fechaTransferencia,
    required this.estado,
    required this.creadoEn,
    required this.actualizadoEn,
    required this.campaniaTitulo,
    required this.cuenta,
    this.descripcion,
    this.motivoRechazo,
    this.comprobante,
  });

  bool get puedeReenviar => estado == 'rechazada';
}
