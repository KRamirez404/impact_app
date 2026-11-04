import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/pending_payment_session.dart';
import '../../infrastructure/datasources/pending_payment_store.dart';
import '../controllers/campaign_detail_controller.dart';
import 'campaign_detail/payment_status_dialog.dart';

class PendingPaymentCard extends StatefulWidget {
  const PendingPaymentCard({super.key});

  @override
  State<PendingPaymentCard> createState() => _PendingPaymentCardState();
}

class _PendingPaymentCardState extends State<PendingPaymentCard> {
  final store = PendingPaymentStore();
  PendingPaymentSession? session;

  @override
  void initState() {
    super.initState();
    session = store.read();
  }

  Future<void> resume() async {
    final pending = session;
    if (pending == null) return;
    final controller = Get.find<CampaignDetailController>();
    final status = await showPaymentStatusDialog(
      context: context,
      donationId: pending.donationId,
      onCheckStatus: controller.checkDonationStatus,
      environment: pending.environment,
      reference: pending.reference,
    );
    if (status != 'pendiente') {
      await store.clear();
      if (mounted) setState(() => session = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = session;
    if (pending == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        color: const Color(0xFFFFF7ED),
        child: ListTile(
          leading: const Icon(Icons.hourglass_top, color: Color(0xFFC2410C)),
          title: const Text('Pago Wompi pendiente'),
          subtitle: Text('Referencia ${pending.reference}'),
          trailing: TextButton(
            onPressed: resume,
            child: const Text('Consultar'),
          ),
        ),
      ),
    );
  }
}
