import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/features/campaigns/domain/entities/campaign_entity.dart';
import 'package:impactapp_flutter/features/campaigns/domain/repositories/campaign_repository.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/create_campaign_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/domain/usecases/get_campaigns_usecase.dart';
import 'package:impactapp_flutter/features/campaigns/presentation/controllers/campaign_list_controller.dart';

class _CampaignRepository implements CampaignRepository {
  @override
  Future<List<CampaignEntity>> getCampaigns({
    int? ciudad,
    int? categoria,
    String? tipoAyuda,
    String? estado,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CampaignEntity _campaign(int id, String tipoAyuda) => CampaignEntity(
  idCampania: id,
  titulo: 'Campaña $id',
  descripcion: 'Descripción',
  idCiudad: 1,
  idCategoria: 1,
  idCreador: 1,
  tipoAyudaRequerida: tipoAyuda,
  metaMonetaria: 0,
  fechaInicio: '2026-01-01',
  fechaFin: '2026-12-31',
  estado: 'activa',
  porcentajeAvance: 0,
);

CampaignEntity _campaignWithStatus(int id, String status, String fechaFin) =>
    CampaignEntity(
      idCampania: id,
      titulo: 'Campaña $id',
      descripcion: 'Descripción',
      idCiudad: 1,
      idCategoria: 1,
      idCreador: 1,
      tipoAyudaRequerida: 'economica',
      metaMonetaria: 0,
      fechaInicio: '2026-01-01',
      fechaFin: fechaFin,
      estado: status,
      porcentajeAvance: 0,
    );

void main() {
  test('filtra campañas por tipo de ayuda y permite limpiar el filtro', () {
    final repository = _CampaignRepository();
    final controller = CampaignListController(
      getCampaignsUseCase: GetCampaignsUseCase(repository),
      createCampaignUseCase: CreateCampaignUseCase(repository),
    );
    controller.campaigns.value = [
      _campaign(1, 'economica'),
      _campaign(2, 'especie'),
    ];

    controller.setFilters(helpType: 'economica');
    expect(
      controller.filteredCampaigns.map((campaign) => campaign.idCampania),
      [1],
    );

    controller.clearFilters();
    expect(controller.filteredCampaigns, hasLength(2));
  });

  test(
    'filtra campañas por estado estadístico sin perder filtros existentes',
    () {
      final repository = _CampaignRepository();
      final controller = CampaignListController(
        getCampaignsUseCase: GetCampaignsUseCase(repository),
        createCampaignUseCase: CreateCampaignUseCase(repository),
      );
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      controller.campaigns.value = [
        _campaignWithStatus(1, 'activa', tomorrow.toIso8601String()),
        _campaignWithStatus(
          2,
          'activa',
          DateTime.now().add(const Duration(days: 20)).toIso8601String(),
        ),
        _campaignWithStatus(3, 'finalizada', tomorrow.toIso8601String()),
      ];

      controller.setCampaignFilter(CampaignListFilter.urgent);
      expect(controller.filteredCampaigns.map((c) => c.idCampania), [1]);

      controller.setCampaignFilter(CampaignListFilter.active);
      expect(controller.filteredCampaigns.map((c) => c.idCampania), [1, 2]);

      controller.setCampaignFilter(CampaignListFilter.verified);
      expect(controller.filteredCampaigns.map((c) => c.idCampania), [1, 2, 3]);
    },
  );
}
