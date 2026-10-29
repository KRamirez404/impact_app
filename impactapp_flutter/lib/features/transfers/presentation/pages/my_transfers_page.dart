import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes/app_routes.dart';
import '../controllers/transfer_controller.dart';
import '../widgets/transfer_status_chip.dart';

class MyTransfersPage extends StatefulWidget {
  const MyTransfersPage({super.key});

  @override
  State<MyTransfersPage> createState() => _MyTransfersPageState();
}

class _MyTransfersPageState extends State<MyTransfersPage> {
  final controller = Get.find<TransferController>();

  @override
  void initState() {
    super.initState();
    controller.loadMine();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis transferencias')),
      body: Obx(() {
        if (controller.loading.value && controller.transfers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty && controller.transfers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(controller.error.value, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: controller.loadMine,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        if (controller.transfers.isEmpty) {
          return const Center(
            child: Text('No tienes transferencias registradas'),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.loadMine,
          child: ListView.builder(
            itemCount: controller.transfers.length,
            itemBuilder: (_, index) {
              final transfer = controller.transfers[index];
              return ListTile(
                title: Text(transfer.campaniaTitulo),
                subtitle: Text(
                  '${NumberFormat.currency(locale: 'es_CO', symbol: r'$ ', decimalDigits: 0).format(transfer.monto)} · ${transfer.referenciaBancaria}',
                ),
                trailing: TransferStatusChip(status: transfer.estado),
                onTap: () => Get.toNamed(
                  '${AppRoutes.transferDetail}/${transfer.idTransferencia}',
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
