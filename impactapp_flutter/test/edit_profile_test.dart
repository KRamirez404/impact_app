import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:impactapp_flutter/features/auth/domain/entities/city_entity.dart';
import 'package:impactapp_flutter/features/auth/domain/entities/user_entity.dart';
import 'package:impactapp_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:impactapp_flutter/features/auth/domain/usecases/get_profile_cities_usecase.dart';
import 'package:impactapp_flutter/features/auth/domain/usecases/login_usecase.dart';
import 'package:impactapp_flutter/features/auth/domain/usecases/register_usecase.dart';
import 'package:impactapp_flutter/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:impactapp_flutter/features/auth/presentation/controllers/auth_controller.dart';
import 'package:impactapp_flutter/features/auth/presentation/pages/edit_profile_page.dart';

class _ProfileRepository implements AuthRepository {
  int saves = 0;
  bool failCities = false;
  Map<String, dynamic>? saved;

  final initialUser = const UserEntity(
    idUsuario: 1,
    nombre: 'María Elena',
    apellido: 'Granados Meza',
    correo: 'perfil@test.co',
    idCiudad: 1,
    ciudadNombre: 'Barranquilla',
    rol: 'donante',
    estado: 'activo',
  );

  @override
  Future<List<CityEntity>> getCities() async {
    if (failCities) throw Exception('Ciudades no disponibles');
    return const [
      CityEntity(idCiudad: 1, nombre: 'Barranquilla'),
      CityEntity(idCiudad: 2, nombre: 'Bogotá'),
    ];
  }

  @override
  Future<UserEntity> updateProfile({
    required String nombre,
    required String apellido,
    required String correo,
    String? telefono,
    String? biografia,
    String? fotoPerfil,
    int? idCiudad,
  }) async {
    saves++;
    saved = {'nombre': nombre, 'apellido': apellido, 'id_ciudad': idCiudad};
    return UserEntity(
      idUsuario: 1,
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      idCiudad: idCiudad,
      rol: 'donante',
      estado: 'activo',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProfileController extends AuthController {
  _ProfileController(_ProfileRepository repository, GetStorage storage)
    : super(
        loginUseCase: LoginUseCase(repository),
        registerUseCase: RegisterUseCase(repository),
        updateProfileUseCase: UpdateProfileUseCase(repository),
        getProfileCitiesUseCase: GetProfileCitiesUseCase(repository),
        repository: repository,
        storage: storage,
      );

  @override
  void showSuccess(String message) {}

  @override
  void showError(String message) {}
}

Finder _inputWithValue(String value) => find.byWidgetPredicate(
  (widget) => widget is TextFormField && widget.controller?.text == value,
);

Future<void> _openProfile(WidgetTester tester) async {
  await tester.pumpWidget(
    GetMaterialApp(
      home: Scaffold(
        body: TextButton(
          onPressed: () => Get.to(() => const EditProfilePage()),
          child: const Text('editar'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('editar'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late _ProfileRepository repository;

  setUp(() async {
    Get.testMode = true;
    temp = await Directory.systemTemp.createTemp('impactapp-profile-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => temp.path,
    );
    final storage = GetStorage(temp.uri.pathSegments.where((part) => part.isNotEmpty).last, temp.path);
    await storage.initStorage;
    repository = _ProfileRepository();
    final controller = _ProfileController(repository, storage);
    Get.put<AuthController>(controller, permanent: true);
    controller.user.value = repository.initialUser;
  });

  tearDown(() async {
    Get.reset();
    await temp.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  testWidgets('conserva nombres compuestos y guarda la ciudad seleccionada', (tester) async {
    await _openProfile(tester);
    expect(_inputWithValue('María Elena'), findsOneWidget);
    expect(_inputWithValue('Granados Meza'), findsOneWidget);

    final cityField = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(cityField);
    await tester.tap(cityField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bogotá').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(repository.saved, {
      'nombre': 'María Elena',
      'apellido': 'Granados Meza',
      'id_ciudad': 2,
    });
    expect(Get.find<AuthController>().user.value?.idCiudad, 2);
  });

  testWidgets('nombre con espacios no rompe avatar ni permite guardar', (tester) async {
    await _openProfile(tester);
    await tester.enterText(_inputWithValue('María Elena'), '   ');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('I'), findsOneWidget);

    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(find.text('Nombres es obligatorio'), findsOneWidget);
    expect(repository.saves, 0);
  });

  testWidgets('permite reintentar la carga de ciudades sin perder la selección', (tester) async {
    repository.failCities = true;
    await _openProfile(tester);
    expect(find.text('Reintentar ciudades'), findsOneWidget);

    repository.failCities = false;
    await tester.ensureVisible(find.text('Reintentar ciudades'));
    await tester.tap(find.text('Reintentar ciudades'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);

    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(repository.saved?['id_ciudad'], 1);
  });
}
