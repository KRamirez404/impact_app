import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/features/auth/presentation/widgets/profile/activity_card.dart';
import 'package:impactapp_flutter/features/auth/presentation/widgets/profile/activity_item.dart';

Widget _harness(ProfileActivityItem item) {
  return MaterialApp(
    home: Scaffold(body: ActivityCard(item: item)),
  );
}

ProfileActivityItem _donation(String? paymentStatus) {
  return ProfileActivityItem(
    title: 'Medicamentos para población vulnerable',
    amount: 50000,
    date: '01/01/2026',
    status: 'Activa',
    campaignId: 1,
    openCampaignDetail: true,
    paymentStatus: paymentStatus,
  );
}

void main() {
  testWidgets('muestra pago pendiente en una donación', (tester) async {
    await tester.pumpWidget(_harness(_donation('pendiente')));
    expect(find.text('Pago pendiente'), findsOneWidget);
  });

  testWidgets('muestra pago confirmado en una donación aprobada', (tester) async {
    await tester.pumpWidget(_harness(_donation('aprobada')));
    expect(find.text('Pago confirmado'), findsOneWidget);
  });

  testWidgets('muestra pago rechazado en una donación fallida', (tester) async {
    await tester.pumpWidget(_harness(_donation('rechazada')));
    expect(find.text('Pago rechazado'), findsOneWidget);
  });

  testWidgets('una campaña del organizador no muestra estado de pago', (tester) async {
    await tester.pumpWidget(
      _harness(
        const ProfileActivityItem(
          title: 'Campaña propia',
          amount: 1000000,
          date: '01/01/2026',
          status: 'Activa',
          campaignId: 2,
        ),
      ),
    );
    expect(find.text('Pago confirmado'), findsNothing);
    expect(find.text('Pago pendiente'), findsNothing);
  });
}
