import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/features/campaigns/domain/entities/donation_checkout_entity.dart';
import 'package:impactapp_flutter/features/campaigns/presentation/widgets/campaign_detail/money_donation_dialog.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeUrlLauncher extends UrlLauncherPlatform {
  final List<String> launchedUrls = [];

  @override
  final LinkDelegate? linkDelegate = null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }
}

Widget _harness({
  required Future<DonationCheckoutEntity?> Function(double) onCheckout,
  required Future<String> Function(int) onCheckStatus,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showMoneyDonationDialog(
              context: context,
              campaignId: 7,
              onCheckout: onCheckout,
              onCheckStatus: onCheckStatus,
            ),
            child: const Text('donar'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late _FakeUrlLauncher fakeLauncher;

  setUp(() {
    fakeLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;
  });

  testWidgets('flujo completo: monto -> Wompi -> pago aprobado', (tester) async {
    double? capturedAmount;
    int? capturedDonationId;

    await tester.pumpWidget(
      _harness(
        onCheckout: (amount) async {
          capturedAmount = amount;
          return DonationCheckoutEntity(
            idDonacion: 21,
            idCampania: 7,
            referencia: 'IMPACTAPP-21-test',
            montoEstimado: amount,
            estadoPago: 'pendiente',
            checkoutUrl:
                'https://checkout.wompi.co/p/?reference=IMPACTAPP-21-test',
          );
        },
        onCheckStatus: (id) async {
          capturedDonationId = id;
          return 'aprobada';
        },
      ),
    );

    await tester.tap(find.text('donar'));
    await tester.pumpAndSettle();
    expect(find.text('Realizar Donación'), findsOneWidget);

    await tester.tap(find.text('Confirmar Donación'));
    await tester.pumpAndSettle();
    expect(find.text('Pagar con Wompi'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pagar con Wompi'));
    await tester.pumpAndSettle();

    expect(capturedAmount, 50000);
    expect(fakeLauncher.launchedUrls, hasLength(1));
    expect(fakeLauncher.launchedUrls.first, contains('checkout.wompi.co'));
    expect(capturedDonationId, 21);
    expect(find.text('Pago aprobado'), findsOneWidget);
  });

  testWidgets('cancelar en la pasarela no inicia el checkout', (tester) async {
    var checkoutCalled = false;

    await tester.pumpWidget(
      _harness(
        onCheckout: (amount) async {
          checkoutCalled = true;
          return null;
        },
        onCheckStatus: (_) async => 'pendiente',
      ),
    );

    await tester.tap(find.text('donar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar Donación'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();

    expect(checkoutCalled, isFalse);
    expect(fakeLauncher.launchedUrls, isEmpty);
  });

  testWidgets('requiere aceptar términos antes de pagar', (tester) async {
    var checkoutCalled = false;

    await tester.pumpWidget(
      _harness(
        onCheckout: (amount) async {
          checkoutCalled = true;
          return null;
        },
        onCheckStatus: (_) async => 'aprobada',
      ),
    );

    await tester.tap(find.text('donar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar Donación'));
    await tester.pumpAndSettle();

    final payButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Pagar con Wompi'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(payButton.onPressed, isNull);
    expect(checkoutCalled, isFalse);
  });
}
