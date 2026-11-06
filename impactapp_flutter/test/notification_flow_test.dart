import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/core/constants/api_constants.dart';
import 'package:impactapp_flutter/features/notifications/infrastructure/datasources/notification_remote_datasource.dart';
import 'package:impactapp_flutter/features/notifications/infrastructure/models/notification_model.dart';

void main() {
  setUp(() {
    ApiConstants.aplicarBaseUrl('https://ejemplo.com/api');
  });

  tearDown(ApiConstants.restaurarBaseUrl);

  test('NotificationModel interpreta leída y no leída', () {
    final noLeida = NotificationModel.fromJson({
      'id_notificacion': 7,
      'tipo': 'donacion_aprobada',
      'asunto': 'Tu donación fue confirmada',
      'estado': 'enviado',
      'leida': false,
      'creado_en': '2026-11-06T14:26:48',
      'enviado_en': '2026-11-06T14:27:00',
    });
    final leida = NotificationModel.fromJson({
      'id_notificacion': 8,
      'tipo': 'bienvenida',
      'asunto': 'Bienvenido',
      'estado': 'enviado',
      'leida': true,
      'creado_en': '2026-11-06T14:26:48',
      'enviado_en': null,
    });

    expect(noLeida.idNotificacion, 7);
    expect(noLeida.leida, isFalse);
    expect(leida.leida, isTrue);
    expect(leida.enviadoEn, isNull);
  });

  test('datasource consulta la bandeja del usuario autenticado', () async {
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
                'total': 1,
                'no_leidas': 1,
                'items': [
                  {
                    'id_notificacion': 4,
                    'tipo': 'campania_creada',
                    'asunto': 'Tu campaña fue creada',
                    'estado': 'enviado',
                    'leida': false,
                    'creado_en': '2026-11-06T14:26:48',
                    'enviado_en': null,
                  },
                ],
              },
            ),
          );
        },
      ),
    );
    final datasource = NotificationRemoteDataSource(dio: dio);

    final items = await datasource.getNotifications();

    expect(captured.method, 'GET');
    expect(captured.uri.toString(), 'https://ejemplo.com/api/notifications');
    expect(items, hasLength(1));
    expect(items.first.asunto, 'Tu campaña fue creada');
    expect(items.first.leida, isFalse);
  });

  test('datasource marca una notificación y todas como leídas', () async {
    final dio = Dio();
    final llamadas = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          llamadas.add(options);
          if (options.path.endsWith('/read-all')) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'marcadas': 3},
              ),
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id_notificacion': 9,
                'tipo': 'donacion_aprobada',
                'asunto': 'Tu donación fue confirmada',
                'estado': 'enviado',
                'leida': true,
                'creado_en': '2026-11-06T14:26:48',
                'enviado_en': '2026-11-06T14:27:00',
              },
            ),
          );
        },
      ),
    );
    final datasource = NotificationRemoteDataSource(dio: dio);

    final leida = await datasource.markRead(9);
    final marcadas = await datasource.markAllRead();

    expect(leida.leida, isTrue);
    expect(marcadas, 3);
    expect(llamadas[0].method, 'POST');
    expect(
      llamadas[0].uri.toString(),
      'https://ejemplo.com/api/notifications/9/read',
    );
    expect(
      llamadas[1].uri.toString(),
      'https://ejemplo.com/api/notifications/read-all',
    );
  });
}
