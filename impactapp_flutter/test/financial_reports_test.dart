import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/features/campaigns/domain/repositories/campaign_repository.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/upload_financial_report_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/infrastructure/models/campaign_model.dart';
import 'package:impactapp_flutter/features/campaigns/presentation/widgets/tabs/docs_tab.dart';

class MockCampaignRepository implements CampaignRepository {
  bool uploadCalled = false;
  int? lastCampaignId;
  String? lastFilePath;
  String? lastFileName;

  @override
  Future<Map<String, dynamic>> uploadFinancialReport(
    int campaignId,
    String filePath,
    String fileName,
  ) async {
    uploadCalled = true;
    lastCampaignId = campaignId;
    lastFilePath = filePath;
    lastFileName = fileName;
    return {
      'id_informe': 1,
      'id_campania': campaignId,
      'nombre_archivo': fileName,
      'mime_type': 'application/pdf',
      'ruta': '/uploads/test.pdf',
    };
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CampaignModel deserializa informe_financiero correctamente', () {
    final json = {
      'id_campania': 42,
      'titulo': 'Campaña con informe',
      'descripcion': 'Probando informe',
      'id_ciudad': 1,
      'id_categoria': 1,
      'id_creador': 10,
      'tipo_ayuda_requerida': 'economica',
      'meta_monetaria': 1000000,
      'fecha_inicio': '2026-01-01',
      'fecha_fin': '2026-12-31',
      'estado': 'activa',
      'porcentaje_avance': 50.0,
      'informe_financiero': {
        'id_informe': 99,
        'id_campania': 42,
        'nombre_archivo': 'informe_q3.pdf',
        'mime_type': 'application/pdf',
        'ruta': '/uploads/informe_q3.pdf',
        'creado_en': '2026-10-15T12:00:00',
      },
    };

    final model = CampaignModel.fromJson(json);
    expect(model.idCampania, 42);
    expect(model.informeFinanciero, isNotNull);
    expect(model.informeFinanciero!['id_informe'], 99);
    expect(model.informeFinanciero!['nombre_archivo'], 'informe_q3.pdf');
  });

  test('UploadFinancialReportUseCase delega al repositorio', () async {
    final mockRepo = MockCampaignRepository();
    final useCase = UploadFinancialReportUseCase(mockRepo);

    final res = await useCase(12, '/tmp/report.pdf', 'report.pdf');

    expect(mockRepo.uploadCalled, isTrue);
    expect(mockRepo.lastCampaignId, 12);
    expect(mockRepo.lastFilePath, '/tmp/report.pdf');
    expect(mockRepo.lastFileName, 'report.pdf');
    expect(res['id_informe'], 1);
  });

  testWidgets('DocsTab muestra tarjeta de informe financiero disponible', (tester) async {
    final report = {
      'id_informe': 1,
      'nombre_archivo': 'balance_general.pdf',
      'mime_type': 'application/pdf',
      'ruta': '/uploads/balance_general.pdf',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DocsTab(
            supports: const [],
            financialReport: report,
            canUploadFinancialReport: false,
          ),
        ),
      ),
    );

    expect(find.text('Informe Financiero de Campaña'), findsOneWidget);
    expect(find.text('balance_general.pdf'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
  });

  testWidgets('DocsTab muestra botón de carga para organizador y responde a clic', (tester) async {
    var uploadClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DocsTab(
            supports: const [],
            financialReport: null,
            canUploadFinancialReport: true,
            onUploadFinancialReport: () {
              uploadClicked = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Cargar informe financiero'), findsOneWidget);
    await tester.tap(find.text('Cargar informe financiero'));
    await tester.pump();

    expect(uploadClicked, isTrue);
  });
}
