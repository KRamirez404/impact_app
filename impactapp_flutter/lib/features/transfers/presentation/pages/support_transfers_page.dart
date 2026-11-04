import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../controllers/support_transfer_controller.dart';
import '../widgets/transfer_status_chip.dart';

class SupportTransfersPage extends StatefulWidget {
  const SupportTransfersPage({super.key});

  @override
  State<SupportTransfersPage> createState() => _SupportTransfersPageState();
}

class _SupportTransfersPageState extends State<SupportTransfersPage> {
  final controller = Get.find<SupportTransferController>();

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Transferencias por revisar')),
    body: Obx(() {
      if (controller.loading.value && controller.transfers.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          children: [
            if (controller.error.value.isNotEmpty)
              ListTile(title: Text(controller.error.value)),
            if (controller.transfers.isEmpty)
              const ListTile(title: Text('No hay transferencias asignadas')),
            for (final transfer in controller.transfers)
              ListTile(
                title: Text(transfer.campaniaTitulo),
                subtitle: Text(
                  'Transferencia #${transfer.idTransferencia} · ${transfer.monto.toStringAsFixed(2)} COP',
                ),
                trailing: TransferStatusChip(status: transfer.estado),
                onTap: () => Get.toNamed(
                  '${AppRoutes.supportTransferDetail}/${transfer.idTransferencia}',
                )?.then((_) => controller.load()),
              ),
          ],
        ),
      );
    }),
  );
}
