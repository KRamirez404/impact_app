import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/core/constants/api_constants.dart';
import 'package:impactapp_flutter/features/transfers/infrastructure/datasources/transfer_remote_datasource.dart';

void main() {
  test(
    'aprobación financiera envía referencia, monto, cuenta y fecha al backend',
    () async {
      final dio = Dio();
      late RequestOptions captured;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id_transferencia': 9,
                  'id_donacion': 10,
                  'id_campania': 2,
                  'id_cuenta_recaudo': 4,
                  'monto': '50000.00',
                  'referencia_bancaria': 'DON-123',
                  'fecha_transferencia': '2026-11-04',
                  'estado': 'aprobada',
                  'cuenta': {
                    'id_cuenta_recaudo': 4,
                    'banco': 'Banco de prueba',
                    'tipo_cuenta': 'ahorros',
                    'numero_cuenta': '****1234',
                    'titular': 'ImpactApp',
                    'estado': 'verificada',
                  },
                  'campania': {'titulo': 'Campaña de prueba'},
                },
              ),
            );
          },
        ),
      );
      final datasource = TransferRemoteDataSource(dio: dio);
      final evidence = {
        'id_cuenta_recaudo': 4,
        'id_movimiento_bancario': 'ABONO-123',
        'monto_abono': '50000.00',
        'fecha_abono': '2026-11-04',
      };

      await datasource.approveSupportTransfer(9, evidence, 'solicitud-9');

      expect(captured.method, 'POST');
      expect(
        captured.uri.toString(),
        '${ApiConstants.baseUrl}/support/transfers/9/approve',
      );
      expect(captured.headers['Idempotency-Key'], 'solicitud-9');
      expect(captured.data, evidence);
    },
  );
}
