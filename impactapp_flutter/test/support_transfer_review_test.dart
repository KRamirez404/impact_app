import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:impactapp_flutter/features/transfers/domain/entities/transfer_entity.dart';
import 'package:impactapp_flutter/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:impactapp_flutter/features/transfers/domain/usecases/manage_support_transfer_usecase.dart';
import 'package:impactapp_flutter/features/transfers/infrastructure/models/transfer_model.dart';
import 'package:impactapp_flutter/features/transfers/presentation/controllers/support_transfer_controller.dart';
import 'package:impactapp_flutter/features/transfers/presentation/pages/support_transfer_detail_page.dart';

class _RepositoryStub implements TransferRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReviewUseCase extends ManageSupportTransferUseCase {
  _ReviewUseCase() : super(_RepositoryStub());

  Map<String, dynamic>? received;

  TransferEntity _transfer(String status) => TransferModel.fromJson({
    'id_transferencia': 9,
    'id_donacion': 10,
    'id_campania': 2,
    'id_cuenta_recaudo': 4,
    'monto': '50000.00',
    'referencia_bancaria': 'REFERENCIA-DONANTE',
    'fecha_transferencia': '2026-10-01',
    'estado': status,
    'cuenta': {
      'id_cuenta_recaudo': 4,
      'banco': 'Banco de prueba',
      'tipo_cuenta': 'ahorros',
      'numero_cuenta': '****1234',
      'titular': 'ImpactApp',
      'estado': 'verificada',
    },
    'campania': {'titulo': 'Campaña de prueba'},
  });

  @override
  Future<TransferEntity> detail(int id) async => _transfer('en_revision');

  @override
  Future<List<TransferEntity>> list() async => [];

  @override
  Future<TransferEntity> approve(
    int id,
    Map<String, dynamic> evidence,
    String key,
  ) async {
    received = evidence;
    return _transfer('aprobada');
  }
}

void main() {
  tearDown(Get.reset);

  testWidgets(
    'no aprueba sin confirmar consulta bancaria y envía la evidencia ingresada',
    (tester) async {
      Get.testMode = true;
      final useCase = _ReviewUseCase();
      Get.put(SupportTransferController(useCase));
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/support/transfers/detail/9',
          getPages: [
            GetPage(
              name: '/support/transfers/detail/:id',
              page: () => const SupportTransferDetailPage(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aprobar abono verificado'));
      await tester.pump();
      expect(useCase.received, isNull);
      await tester.scrollUntilVisible(
        find.textContaining('Consulta el banco y completa'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('Consulta el banco y completa'),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(
          TextField,
          'Identificador del movimiento en el banco',
        ),
        'MOV-9',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Importe confirmado en el banco (COP)'),
        '50000.00',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Fecha del abono (AAAA-MM-DD)'),
        '2026-11-04',
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(find.text('Aprobar abono verificado'));
      await tester.tap(find.text('Aprobar abono verificado'));
      await tester.pumpAndSettle();

      expect(useCase.received, {
        'id_cuenta_recaudo': 4,
        'id_movimiento_bancario': 'MOV-9',
        'monto_abono': '50000.00',
        'fecha_abono': '2026-11-04',
      });
      expect(find.text('Aprobada'), findsOneWidget);
    },
  );
}
