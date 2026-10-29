class BankAccountEntity {
  final int idCuentaRecaudo;
  final String banco;
  final String tipoCuenta;
  final String numeroCuenta;
  final String titular;
  final String moneda;
  final String estado;

  const BankAccountEntity({
    required this.idCuentaRecaudo,
    required this.banco,
    required this.tipoCuenta,
    required this.numeroCuenta,
    required this.titular,
    required this.moneda,
    required this.estado,
  });

  bool get estaVerificada => estado == 'verificada';
}
