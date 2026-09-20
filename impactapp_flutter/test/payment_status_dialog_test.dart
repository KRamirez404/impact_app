import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/features/campaigns/presentation/widgets/campaign_detail/payment_status_dialog.dart';

Widget _harness(Future<String> Function(int) onCheckStatus) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showPaymentStatusDialog(
              context: context,
              donationId: 1,
              onCheckStatus: onCheckStatus,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('muestra pago aprobado y permite cerrar', (tester) async {
    await tester.pumpWidget(_harness((_) async => 'aprobada'));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Pago aprobado'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);
    expect(find.text('Actualizar'), findsNothing);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Pago aprobado'), findsNothing);
  });

  testWidgets('pago pendiente permite actualizar a aprobado', (tester) async {
    var status = 'pendiente';
    await tester.pumpWidget(_harness((_) async => status));
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Pago pendiente'), findsOneWidget);
    expect(find.text('Actualizar'), findsOneWidget);

    status = 'aprobada';
    await tester.tap(find.text('Actualizar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Pago aprobado'), findsOneWidget);
  });

  testWidgets('muestra pago rechazado', (tester) async {
    await tester.pumpWidget(_harness((_) async => 'rechazada'));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Pago rechazado'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);
  });
}
