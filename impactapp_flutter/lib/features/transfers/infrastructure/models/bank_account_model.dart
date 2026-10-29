import '../../domain/entities/bank_account_entity.dart';

class BankAccountModel extends BankAccountEntity {
  const BankAccountModel({
    required super.idCuentaRecaudo,
    required super.banco,
    required super.tipoCuenta,
    required super.numeroCuenta,
    required super.titular,
    required super.moneda,
    required super.estado,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      idCuentaRecaudo: (json['id_cuenta_recaudo'] as num).toInt(),
      banco: json['banco']?.toString() ?? '',
      tipoCuenta: json['tipo_cuenta']?.toString() ?? '',
      numeroCuenta: json['numero_cuenta']?.toString() ?? '',
      titular: json['titular']?.toString() ?? '',
      moneda: json['moneda']?.toString() ?? 'COP',
      estado: json['estado']?.toString() ?? '',
    );
  }
}
