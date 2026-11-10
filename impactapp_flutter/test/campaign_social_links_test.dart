import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/features/campaigns/domain/entities/campaign_entity.dart';
import 'package:impactapp_flutter/features/campaigns/infrastructure/models/campaign_model.dart';
import 'package:impactapp_flutter/features/campaigns/presentation/widgets/tabs/info_tab.dart';

CampaignEntity _makeCampaign({
  Map<String, dynamic> redes = const {},
}) => CampaignEntity(
  idCampania: 1,
  titulo: 'Campaña con redes',
  descripcion: 'Descripción de prueba',
  idCiudad: 1,
  idCategoria: 1,
  idCreador: 1,
  tipoAyudaRequerida: 'economica',
  metaMonetaria: 1000000,
  fechaInicio: '2026-01-01',
  fechaFin: '2026-12-31',
  estado: 'activa',
  porcentajeAvance: 50,
  creadorNombre: 'Fundación',
  creadorApellido: 'Esperanza',
  creadorCorreo: 'contacto@esperanza.org',
  creadorRedesSociales: redes,
);

void main() {
  test('CampaignModel.fromJson deserializa redes_sociales del creador', () {
    final json = {
      'id_campania': 10,
      'titulo': 'Test Campaña',
      'descripcion': 'Desc',
      'id_ciudad': 1,
      'id_categoria': 1,
      'id_creador': 5,
      'tipo_ayuda_requerida': 'economica',
      'meta_monetaria': 1000,
      'fecha_inicio': '2026-01-01',
      'fecha_fin': '2026-12-31',
      'estado': 'activa',
      'porcentaje_avance': 10,
      'creador': {
        'nombre': 'Carlos',
        'apellido': 'Pérez',
        'correo': 'carlos@test.org',
        'redes_sociales': {
          'instagram': 'https://instagram.com/carlos_perez',
          'sitio_web': 'https://carlosperez.org',
        },
      },
    };

    final model = CampaignModel.fromJson(json);
    expect(model.creadorRedesSociales['instagram'], 'https://instagram.com/carlos_perez');
    expect(model.creadorRedesSociales['sitio_web'], 'https://carlosperez.org');
  });

  testWidgets('InfoTab renderiza enlaces de redes sociales cuando están presentes', (tester) async {
    final campaign = _makeCampaign(
      redes: {
        'instagram': 'https://instagram.com/fundacion',
        'sitio_web': 'https://fundacion.org',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InfoTab(campaign: campaign),
        ),
      ),
    );

    expect(find.text('Redes sociales de seguimiento'), findsOneWidget);
    expect(find.text('instagram'), findsOneWidget);
    expect(find.text('sitio_web'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.language), findsOneWidget);
  });

  testWidgets('InfoTab muestra mensaje informativo si creadorRedesSociales esta vacio', (tester) async {
    final campaign = _makeCampaign(redes: {});

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InfoTab(campaign: campaign),
        ),
      ),
    );

    expect(find.text('Redes sociales de seguimiento'), findsOneWidget);
    expect(
      find.text('El organizador no ha registrado redes sociales externas para seguimiento.'),
      findsOneWidget,
    );
  });

  testWidgets('InfoTab no renderiza enlaces con schemes invalidos o inseguros', (tester) async {
    final campaign = _makeCampaign(
      redes: {
        'inseguro': 'javascript:alert(1)',
        'valido': 'https://valido.org',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InfoTab(campaign: campaign),
        ),
      ),
    );

    expect(find.text('valido'), findsOneWidget);
    expect(find.text('inseguro'), findsNothing);
  });
}
