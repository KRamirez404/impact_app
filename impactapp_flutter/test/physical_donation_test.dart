import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/features/campaigns/presentation/widgets/campaign_detail/physical_donation_dialog.dart';

void main() {
  test('construye el payload con monto y punto', () {
    final donation = physicalDonationPayload(
      campaignId: 3,
      pointId: 7,
      type: 'alimentos',
      estimatedAmount: 12500,
      description: 'Canasta',
    );

    expect(donation, {
      'id_campania': 3,
      'id_punto': 7,
      'tipo': 'alimentos',
      'monto_estimado': 12500,
      'descripcion': 'Canasta',
    });
  });

  testWidgets('informa cuando la campaña no tiene puntos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showPhysicalDonationDialog(
              context: context,
              campaignId: 3,
              puntosRecoleccion: const [],
              onDonate: (_) async {},
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pump();

    expect(
      find.text('Esta campaña no tiene puntos de recolección registrados aún'),
      findsOneWidget,
    );
  });
}
