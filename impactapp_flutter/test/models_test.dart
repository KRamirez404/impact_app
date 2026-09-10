import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/features/auth/infrastructure/models/user_model.dart';
import 'package:impactapp_flutter/features/campaigns/infrastructure/models/donation_with_campaign_model.dart';

void main() {
  group('UserModel.fromJson', () {
    test('parsea rol donante/organizador/soporte', () {
      expect(
        UserModel.fromJson({'rol': 'donante'}).rol,
        'donante',
      );
      expect(
        UserModel.fromJson({'rol': 'organizador'}).rol,
        'organizador',
      );
      expect(
        UserModel.fromJson({'rol': 'soporte'}).rol,
        'soporte',
      );
    });

    test('usa rol por defecto si no llega', () {
      expect(UserModel.fromJson({}).rol, 'usuario');
    });
  });

  group('DonationWithCampaignModel.fromJson', () {
    final json = {
      'id_donacion': 7,
      'id_campania': 3,
      'monto_estimado': 50000,
      'tipo': 'economica',
      'fecha_donacion': '2026-09-01T10:00:00',
      'campania': {
        'id_campania': 3,
        'titulo': 'Medicamentos',
        'estado': 'activa',
        'fecha_fin': '2026-12-01',
        'total_avances': 2,
        'nuevos_avances': 1,
      },
    };

    test('extrae datos de campaña y avances', () {
      final model = DonationWithCampaignModel.fromJson(json);
      expect(model.idCampania, 3);
      expect(model.campaignTitulo, 'Medicamentos');
      expect(model.campaignEstado, 'activa');
      expect(model.totalAvances, 2);
      expect(model.nuevosAvances, 1);
    });

    test('avances por defecto en 0', () {
      final model = DonationWithCampaignModel.fromJson({
        'id_donacion': 1,
        'id_campania': 1,
        'campania': {'titulo': 'X', 'estado': 'activa'},
      });
      expect(model.totalAvances, 0);
      expect(model.nuevosAvances, 0);
    });
  });
}
