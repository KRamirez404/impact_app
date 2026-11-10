import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/features/campaigns/domain/entities/campaign_entity.dart';
import 'package:impactapp_flutter/features/campaigns/domain/repositories/campaign_repository.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/create_donation_checkout_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/donate_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/get_campaign_detail_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/get_donation_status_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/toggle_like_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/update_campaign_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/presentation/controllers/campaign_detail_controller.dart';

class _CampaignRepository implements CampaignRepository {
  @override
  Future<CampaignEntity> getCampaignDetail(int id) async => CampaignEntity(
    idCampania: id,
    titulo: 'Campaña',
    descripcion: 'Descripción',
    idCiudad: 1,
    idCategoria: 1,
    idCreador: 1,
    tipoAyudaRequerida: 'especie',
    metaMonetaria: 0,
    fechaInicio: '2026-01-01',
    fechaFin: '2026-12-31',
    estado: 'activa',
    porcentajeAvance: 0,
    puntosRecoleccion: [
      {'id_punto': 7, 'nombre': 'Punto norte'},
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('expone los puntos de recolección de la campaña cargada', () async {
    final repository = _CampaignRepository();
    final controller = CampaignDetailController(
      getCampaignDetailUseCase: GetCampaignDetailUseCase(repository),
      donateUseCase: DonateUseCase(repository),
      toggleLikeUseCase: ToggleLikeUseCase(repository),
      createDonationCheckoutUseCase: CreateDonationCheckoutUseCase(repository),
      getDonationStatusUseCase: GetDonationStatusUseCase(repository),
      updateCampaignUseCase: UpdateCampaignUseCase(repository),
    );

    await controller.loadCampaign(3);

    expect(controller.collectionPoints.single['id_punto'], 7);
  });
}
