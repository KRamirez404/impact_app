import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:impactapp_flutter/features/campaigns/domain/entities/campaign_entity.dart';
import 'package:impactapp_flutter/features/campaigns/domain/repositories/campaign_repository.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/create_campaign_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/create_donation_checkout_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/donate_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/get_campaign_detail_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/get_campaigns_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/get_donation_status_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/toggle_like_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/update_campaign_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/presentation/controllers/campaign_detail_controller.dart';
import 'package:impactapp_flutter/features/campaigns/presentation/controllers/campaign_list_controller.dart';
import 'package:impactapp_flutter/features/campaigns/presentation/pages/edit_campaign_page.dart';

CampaignEntity _campaign({
  required String estado,
  String? cuentaRecaudo,
  String titulo = 'Campaña original',
}) {
  return CampaignEntity(
    idCampania: 1,
    titulo: titulo,
    descripcion: 'Descripción original',
    idCiudad: 1,
    idCategoria: 1,
    idCreador: 10,
    tipoAyudaRequerida: 'economica',
    metaMonetaria: 500000,
    fechaInicio: '2026-01-01',
    fechaFin: '2030-01-01',
    estado: estado,
    porcentajeAvance: 0,
    cuentaRecaudo: cuentaRecaudo,
    ciudadNombre: 'Bogotá',
    categoriaNombre: 'Salud',
  );
}

class _Repo implements CampaignRepository {
  _Repo({this.campaign, this.updated});
  CampaignEntity? campaign;
  CampaignEntity? updated;
  Map<String, dynamic>? lastPayload;
  int? lastId;

  @override
  Future<CampaignEntity> getCampaignDetail(int id) async => campaign!;

  @override
  Future<CampaignEntity> updateCampaign(int id, Map<String, dynamic> payload) async {
    lastId = id;
    lastPayload = payload;
    return updated ?? campaign!;
  }

  @override
  Future<List<CampaignEntity>> getCampaigns({
    int? ciudad,
    int? categoria,
    String? tipoAyuda,
    String? estado,
  }) async => campaign == null ? [] : [campaign!];

  @override
  Future<List<Map<String, dynamic>>> getCities() async => [
        {'id_ciudad': 1, 'nombre': 'Bogotá', 'departamento': 'Cundinamarca'},
      ];

  @override
  Future<List<Map<String, dynamic>>> getCategories() async => [
        {'id_categoria': 1, 'nombre': 'Salud'},
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CampaignDetailController _detailController(_Repo repo) {
  return CampaignDetailController(
    getCampaignDetailUseCase: GetCampaignDetailUseCase(repo),
    donateUseCase: DonateUseCase(repo),
    toggleLikeUseCase: ToggleLikeUseCase(repo),
    createDonationCheckoutUseCase: CreateDonationCheckoutUseCase(repo),
    getDonationStatusUseCase: GetDonationStatusUseCase(repo),
    updateCampaignUseCase: UpdateCampaignUseCase(repo),
  );
}

class _TestListController extends CampaignListController {
  _TestListController({
    required super.getCampaignsUseCase,
    required super.createCampaignUseCase,
  });

  @override
  Future<void> fetchCampaigns() async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  test('UpdateCampaignUseCase delega la actualización al repositorio', () async {
    final original = _campaign(estado: 'en_verificacion', cuentaRecaudo: '111');
    final changed = original.copyWith(titulo: 'Nuevo título');
    final repo = _Repo(campaign: original, updated: changed);
    final useCase = UpdateCampaignUseCase(repo);

    final result = await useCase(1, {'titulo': 'Nuevo título'});

    expect(repo.lastId, 1);
    expect(repo.lastPayload, {'titulo': 'Nuevo título'});
    expect(result.titulo, 'Nuevo título');
  });

  testWidgets('editCampaign actualiza el detalle y sincroniza la lista en tiempo real', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox.shrink()));
    final original = _campaign(estado: 'en_verificacion', titulo: 'Antes');
    final changed = original.copyWith(titulo: 'Después');
    final repo = _Repo(campaign: original, updated: changed);
    final detail = _detailController(repo);
    final list = _TestListController(
      getCampaignsUseCase: GetCampaignsUseCase(repo),
      createCampaignUseCase: CreateCampaignUseCase(repo),
    );
    Get.put<CampaignListController>(list);
    detail.campaign.value = original;
    list.campaigns.assignAll([original]);

    final result = await detail.editCampaign(1, {'titulo': 'Después'});
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(result, isNotNull);
    expect(detail.campaign.value?.titulo, 'Después');
    expect(list.campaigns.single.titulo, 'Después');
  });

  testWidgets('bloquea cuenta de recaudo cuando la campaña está verificada/activa', (tester) async {
    final repo = _Repo(
      campaign: _campaign(estado: 'activa', cuentaRecaudo: '1234567890'),
    );
    final detail = _detailController(repo);
    detail.campaign.value = repo.campaign;
    Get.put<CampaignDetailController>(detail);
    Get.put<CampaignRepository>(repo);
    Get.parameters = {'id': '1'};

    await tester.pumpWidget(const GetMaterialApp(home: EditCampaignPage()));
    await tester.pumpAndSettle();

    final cuentaField = find.widgetWithText(TextFormField, '1234567890');
    expect(cuentaField, findsOneWidget);
    final field = tester.widget<TextFormField>(cuentaField);
    expect(field.enabled, isFalse);
    expect(
      find.text('No se puede modificar la cuenta de recaudo de una campaña verificada/aprobada.'),
      findsOneWidget,
    );
  });

  testWidgets('permite editar cuenta de recaudo cuando la campaña no está activa', (tester) async {
    final repo = _Repo(
      campaign: _campaign(estado: 'en_verificacion', cuentaRecaudo: '1234567890'),
    );
    final detail = _detailController(repo);
    detail.campaign.value = repo.campaign;
    Get.put<CampaignDetailController>(detail);
    Get.put<CampaignRepository>(repo);
    Get.parameters = {'id': '1'};

    await tester.pumpWidget(const GetMaterialApp(home: EditCampaignPage()));
    await tester.pumpAndSettle();

    final cuentaField = find.widgetWithText(TextFormField, '1234567890');
    expect(cuentaField, findsOneWidget);
    final field = tester.widget<TextFormField>(cuentaField);
    expect(field.enabled, isTrue);
    expect(
      find.text('No se puede modificar la cuenta de recaudo de una campaña verificada/aprobada.'),
      findsNothing,
    );
  });
}
