import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:impactapp_flutter/features/support/domain/entities/support_user_entity.dart';
import 'package:impactapp_flutter/features/support/domain/repositories/support_repository.dart';
import 'package:impactapp_flutter/features/support/domain/usecases/get_support_users_usecase.dart';
import 'package:impactapp_flutter/features/support/domain/usecases/manage_support_user_usecase.dart';
import 'package:impactapp_flutter/features/support/infrastructure/models/support_user_model.dart';
import 'package:impactapp_flutter/features/support/presentation/controllers/support_controller.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/get_campaign_detail_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/repositories/campaign_repository.dart';
import 'package:impactapp_flutter/features/support/domain/usecases/approve_campaign_usecase.dart';
import 'package:impactapp_flutter/features/support/domain/usecases/reject_campaign_usecase.dart';
import 'package:impactapp_flutter/features/support/domain/usecases/invalidate_campaign_usecase.dart';
import 'package:impactapp_flutter/features/support/domain/usecases/delete_campaign_usecase.dart';
import 'package:impactapp_flutter/features/support/domain/usecases/restore_campaign_usecase.dart';
import 'package:impactapp_flutter/features/support/domain/usecases/get_support_summary_usecase.dart';
import 'package:impactapp_flutter/features/support/domain/usecases/get_support_campaigns_usecase.dart';

class _FakeSupportRepo implements SupportRepository {
  List<SupportUserEntity> users = [
    SupportUserModel.fromJson({
      'id_usuario': 1,
      'nombre': 'Juan',
      'apellido': 'Pérez',
      'correo': 'juan@test.co',
      'rol': 'donante',
      'estado': 'activo',
    }),
    SupportUserModel.fromJson({
      'id_usuario': 2,
      'nombre': 'Admin',
      'apellido': 'Soporte',
      'correo': 'soporte@test.co',
      'rol': 'soporte',
      'estado': 'activo',
    }),
  ];

  int? lastBlockedId;
  int? lastUnblockedId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<SupportUserEntity>> getUsers() async => users;

  @override
  Future<void> blockUser(int userId) async {
    lastBlockedId = userId;
    final idx = users.indexWhere((u) => u.idUsuario == userId);
    if (idx != -1) {
      users[idx] = SupportUserModel.fromJson({
        'id_usuario': users[idx].idUsuario,
        'nombre': users[idx].nombre,
        'apellido': users[idx].apellido,
        'correo': users[idx].correo,
        'rol': users[idx].rol,
        'estado': 'bloqueado',
      });
    }
  }

  @override
  Future<void> unblockUser(int userId) async {
    lastUnblockedId = userId;
    final idx = users.indexWhere((u) => u.idUsuario == userId);
    if (idx != -1) {
      users[idx] = SupportUserModel.fromJson({
        'id_usuario': users[idx].idUsuario,
        'nombre': users[idx].nombre,
        'apellido': users[idx].apellido,
        'correo': users[idx].correo,
        'rol': users[idx].rol,
        'estado': 'activo',
      });
    }
  }
}

class _FakeCampaignRepo implements CampaignRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  test('GetSupportUsersUseCase obtiene listado de usuarios correctamente', () async {
    final repo = _FakeSupportRepo();
    final useCase = GetSupportUsersUseCase(repo);

    final result = await useCase();
    expect(result.length, 2);
    expect(result.first.nombre, 'Juan');
    expect(result.first.estado, 'activo');
  });

  test('ManageSupportUserUseCase bloquea y desbloquea usuario', () async {
    final repo = _FakeSupportRepo();
    final useCase = ManageSupportUserUseCase(repo);

    await useCase.block(1);
    expect(repo.lastBlockedId, 1);
    expect(repo.users.first.estado, 'bloqueado');

    await useCase.unblock(1);
    expect(repo.lastUnblockedId, 1);
    expect(repo.users.first.estado, 'activo');
  });

  testWidgets('SupportController carga usuarios y conmuta estado con toggleUser', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox.shrink()));
    final supportRepo = _FakeSupportRepo();
    final campaignRepo = _FakeCampaignRepo();

    final controller = SupportController(
      GetCampaignDetailUseCase(campaignRepo),
      GetSupportCampaignsUseCase(supportRepo),
      GetSupportSummaryUseCase(supportRepo),
      ApproveCampaignUseCase(supportRepo),
      RejectCampaignUseCase(supportRepo),
      InvalidateCampaignUseCase(supportRepo),
      DeleteCampaignUseCase(supportRepo),
      RestoreCampaignUseCase(supportRepo),
      GetSupportUsersUseCase(supportRepo),
      ManageSupportUserUseCase(supportRepo),
    );

    await controller.loadUsers();
    expect(controller.supportUsers.length, 2);
    expect(controller.supportUsers.first.estado, 'activo');

    // Bloquear donante activo
    await controller.toggleUser(controller.supportUsers.first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(controller.supportUsers.first.estado, 'bloqueado');

    // Desbloquear donante bloqueado
    await controller.toggleUser(controller.supportUsers.first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(controller.supportUsers.first.estado, 'activo');
  });
}
