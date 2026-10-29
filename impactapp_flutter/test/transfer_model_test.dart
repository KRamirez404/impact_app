import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/features/transfers/infrastructure/models/bank_account_model.dart';
import 'package:impactapp_flutter/features/transfers/infrastructure/models/transfer_model.dart';

void main() {
  test('interpreta la cuenta verificada entregada al donante', () {
    final account = BankAccountModel.fromJson({
      'id_cuenta_recaudo': 4,
      'banco': 'Banco de prueba',
      'tipo_cuenta': 'ahorros',
      'numero_cuenta': '1234567890',
      'titular': 'Fundación Prueba',
      'moneda': 'COP',
      'estado': 'verificada',
    });

    expect(account.idCuentaRecaudo, 4);
    expect(account.numeroCuenta, '1234567890');
    expect(account.estaVerificada, isTrue);
  });

  test('interpreta rechazo, campaña y comprobante de una transferencia', () {
    final transfer = TransferModel.fromJson({
      'id_transferencia': 9,
      'id_donacion': 20,
      'id_donante': 3,
      'id_campania': 7,
      'id_cuenta_recaudo': 4,
      'monto': '50000.00',
      'moneda': 'COP',
      'referencia_bancaria': 'REF-123',
      'fecha_transferencia': '2026-10-22',
      'descripcion': 'Aporte',
      'estado': 'rechazada',
      'motivo_rechazo': 'No coincide el valor',
      'creado_en': '2026-10-22T12:00:00',
      'actualizado_en': '2026-10-22T13:00:00',
      'cuenta': {
        'id_cuenta_recaudo': 4,
        'banco': 'Banco de prueba',
        'tipo_cuenta': 'ahorros',
        'numero_cuenta': '****7890',
        'titular': 'Fundación Prueba',
        'moneda': 'COP',
        'estado': 'verificada',
      },
      'campania': {
        'id_campania': 7,
        'titulo': 'Campaña de prueba',
        'estado': 'activa',
        'eliminada': false,
      },
      'comprobante': {
        'id_comprobante': 2,
        'id_transferencia': 9,
        'version': 1,
        'mime': 'application/pdf',
        'tamano_bytes': 2048,
        'sha256': 'abc123',
        'estado_tecnico': 'validado',
        'subido_por': 3,
        'creado_en': '2026-10-22T12:10:00',
      },
    });

    expect(transfer.monto, 50000);
    expect(transfer.campaniaTitulo, 'Campaña de prueba');
    expect(transfer.comprobante?.mime, 'application/pdf');
    expect(transfer.puedeReenviar, isTrue);
  });
}
