import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:impactapp_flutter/app/routes/app_routes.dart';
import 'package:impactapp_flutter/features/auth/domain/entities/user_entity.dart';
import 'package:impactapp_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:impactapp_flutter/features/auth/domain/usecases/get_profile_cities_usecase.dart';
import 'package:impactapp_flutter/features/auth/domain/usecases/login_usecase.dart';
import 'package:impactapp_flutter/features/auth/domain/usecases/register_usecase.dart';
import 'package:impactapp_flutter/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:impactapp_flutter/features/auth/presentation/controllers/auth_controller.dart';
import 'package:impactapp_flutter/features/campaigns/domain/entities/campaign_entity.dart';
import 'package:impactapp_flutter/features/campaigns/domain/entities/top_donor_entity.dart';
import 'package:impactapp_flutter/features/campaigns/domain/repositories/campaign_repository.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/create_campaign_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/get_campaigns_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/get_top_donors_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/presentation/controllers/campaign_list_controller.dart';
import 'package:impactapp_flutter/features/campaigns/presentation/pages/explore_page.dart';
import 'package:impactapp_flutter/features/home/presentation/controllers/home_controller.dart';
import 'package:impactapp_flutter/features/home/presentation/pages/home_page.dart';

class _FakeCampaignRepository implements CampaignRepository {
  @override
  Future<List<CampaignEntity>> getCampaigns({
    int? ciudad,
    int? categoria,
    String? tipoAyuda,
    String? estado,
  }) async => [];

  @override
  Future<List<TopDonorEntity>> getTopDonors({int limit = 5}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CampaignEntity _sampleCampaign({
  required int id,
  required String status,
  required String fechaFin,
}) => CampaignEntity(
  idCampania: id,
  titulo: 'Campaña $id',
  descripcion: 'Descripción $id',
  idCiudad: 1,
  idCategoria: 1,
  idCreador: 1,
  tipoAyudaRequerida: 'economica',
  metaMonetaria: 1000000,
  fechaInicio: '2026-01-01',
  fechaFin: fechaFin,
  estado: status,
  porcentajeAvance: 50,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;

  setUp(() async {
    Get.testMode = true;
    temp = await Directory.systemTemp.createTemp('impactapp-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => temp.path,
        );
    final storage = GetStorage(
      temp.uri.pathSegments.where((p) => p.isNotEmpty).last,
      temp.path,
    );
    await storage.initStorage;

    final campRepo = _FakeCampaignRepository();
    final authRepo = _FakeAuthRepository();

    final campaignCtrl = CampaignListController(
      getCampaignsUseCase: GetCampaignsUseCase(campRepo),
      createCampaignUseCase: CreateCampaignUseCase(campRepo),
    );
    final authCtrl = AuthController(
      loginUseCase: LoginUseCase(authRepo),
      registerUseCase: RegisterUseCase(authRepo),
      updateProfileUseCase: UpdateProfileUseCase(authRepo),
      getProfileCitiesUseCase: GetProfileCitiesUseCase(authRepo),
      repository: authRepo,
      storage: storage,
    );
    final homeCtrl = HomeController(
      getTopDonorsUseCase: GetTopDonorsUseCase(campRepo),
    );

    authCtrl.user.value = const UserEntity(
      idUsuario: 1,
      nombre: 'Usuario Prueba',
      apellido: 'ImpactApp',
      correo: 'test@impactapp.co',
      idCiudad: 1,
      ciudadNombre: 'Bogotá',
      rol: 'donante',
      estado: 'activo',
    );

    final tomorrow = DateTime.now().add(const Duration(days: 2));
    final nextMonth = DateTime.now().add(const Duration(days: 30));

    campaignCtrl.campaigns.value = [
      _sampleCampaign(id: 1, status: 'activa', fechaFin: tomorrow.toIso8601String()),
      _sampleCampaign(id: 2, status: 'activa', fechaFin: nextMonth.toIso8601String()),
      _sampleCampaign(id: 3, status: 'finalizada', fechaFin: tomorrow.toIso8601String()),
    ];

    Get.put<CampaignListController>(campaignCtrl, permanent: true);
    Get.put<AuthController>(authCtrl, permanent: true);
    Get.put<HomeController>(homeCtrl, permanent: true);
  });

  tearDown(() async {
    Get.reset();
    await temp.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });

  Widget createTestApp() {
    return GetMaterialApp(
      initialRoute: AppRoutes.home,
      getPages: [
        GetPage(
          name: AppRoutes.home,
          page: () => HomePage(),
        ),
        GetPage(
          name: AppRoutes.explore,
          page: () => const ExplorePage(),
        ),
      ],
    );
  }

  testWidgets('widget Activas navega a Explore con filtro active y permite volver', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final activasFinder = find.text('Activas');
    expect(activasFinder, findsOneWidget);

    await tester.tap(activasFinder);
    await tester.pumpAndSettle();

    final campaignCtrl = Get.find<CampaignListController>();
    expect(campaignCtrl.selectedCampaignFilter.value, CampaignListFilter.active);
    expect(Get.currentRoute, AppRoutes.explore);

    Get.back();
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.home);
  });

  testWidgets('widget Urgentes navega a Explore con filtro urgent y permite volver', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final urgentesFinder = find.text('Urgentes');
    expect(urgentesFinder, findsOneWidget);

    await tester.tap(urgentesFinder);
    await tester.pumpAndSettle();

    final campaignCtrl = Get.find<CampaignListController>();
    expect(campaignCtrl.selectedCampaignFilter.value, CampaignListFilter.urgent);
    expect(Get.currentRoute, AppRoutes.explore);

    Get.back();
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.home);
  });

  testWidgets('widget Verificadas navega a Explore con filtro verified y permite volver', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final verificadasFinder = find.text('Verificadas');
    expect(verificadasFinder, findsOneWidget);

    await tester.tap(verificadasFinder);
    await tester.pumpAndSettle();

    final campaignCtrl = Get.find<CampaignListController>();
    expect(campaignCtrl.selectedCampaignFilter.value, CampaignListFilter.verified);
    expect(Get.currentRoute, AppRoutes.explore);

    Get.back();
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.home);
  });
}
