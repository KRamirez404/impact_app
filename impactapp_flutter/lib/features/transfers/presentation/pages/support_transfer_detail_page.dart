import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/support_transfer_controller.dart';
import '../widgets/transfer_status_chip.dart';

class SupportTransferDetailPage extends StatefulWidget {
  const SupportTransferDetailPage({super.key});

  @override
  State<SupportTransferDetailPage> createState() =>
      _SupportTransferDetailPageState();
}

class _SupportTransferDetailPageState extends State<SupportTransferDetailPage> {
  final controller = Get.find<SupportTransferController>();
  final movement = TextEditingController();
  final amount = TextEditingController();
  final bankDate = TextEditingController();
  final reason = TextEditingController();
  bool confirmed = false;

  int get transferId => int.tryParse(Get.parameters['id'] ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    controller.detail(transferId);
  }

  @override
  void dispose() {
    movement.dispose();
    amount.dispose();
    bankDate.dispose();
    reason.dispose();
    super.dispose();
  }

  Future<void> download() async {
    final data = await controller.receipt(transferId);
    final receipt = controller.current.value?.comprobante;
    if (data == null || receipt == null) return;
    final extension = switch (receipt.mime) {
      'application/pdf' => 'pdf',
      'image/png' => 'png',
      _ => 'jpg',
    };
    await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar comprobante',
      fileName: 'comprobante_$transferId.$extension',
      bytes: data,
    );
  }

  Future<void> approve() async {
    final transfer = controller.current.value;
    if (transfer == null) return;
    if (!confirmed ||
        movement.text.trim().isEmpty ||
        amount.text.trim().isEmpty ||
        bankDate.text.trim().isEmpty) {
      controller.error.value =
          'Consulta el banco y completa identificador, importe y fecha antes de aprobar';
      return;
    }
    await controller.approve(transferId, {
      'id_cuenta_recaudo': transfer.idCuentaRecaudo,
      'id_movimiento_bancario': movement.text.trim(),
      'monto_abono': amount.text.trim(),
      'fecha_abono': bankDate.text.trim(),
    });
  }

  Future<void> reject() async {
    if (reason.text.trim().isEmpty) {
      controller.error.value = 'Indica el motivo del rechazo';
      return;
    }
    await controller.reject(transferId, reason.text.trim());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Revisión de transferencia')),
    body: Obx(() {
      final transfer = controller.current.value;
      if (controller.loading.value && transfer == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (transfer == null) {
        return Center(
          child: Text(
            controller.error.value.isEmpty
                ? 'Transferencia no encontrada'
                : controller.error.value,
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            transfer.campaniaTitulo,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TransferStatusChip(status: transfer.estado),
          const SizedBox(height: 12),
          Text('Monto declarado: ${transfer.monto.toStringAsFixed(2)} COP'),
          Text('Referencia declarada: ${transfer.referenciaBancaria}'),
          Text('Fecha declarada: ${transfer.fechaTransferencia}'),
          Text(
            'Cuenta: ${transfer.cuenta.banco} · ${transfer.cuenta.numeroCuenta}',
          ),
          if (transfer.comprobante != null)
            OutlinedButton.icon(
              onPressed: controller.loading.value ? null : download,
              icon: const Icon(Icons.download),
              label: const Text('Descargar comprobante privado'),
            ),
          if (transfer.estado == 'registrada' && transfer.comprobante != null)
            ElevatedButton(
              onPressed: controller.loading.value
                  ? null
                  : () => controller.claim(transferId),
              child: const Text('Tomar revisión'),
            ),
          if (transfer.estado == 'en_revision') ...[
            const SizedBox(height: 16),
            const Text(
              'Consulta el movimiento en la cuenta bancaria. El comprobante del donante no acredita el abono.',
            ),
            TextField(
              controller: movement,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Identificador del movimiento en el banco',
              ),
            ),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Importe confirmado en el banco (COP)',
              ),
            ),
            TextField(
              controller: bankDate,
              decoration: const InputDecoration(
                labelText: 'Fecha del abono (AAAA-MM-DD)',
              ),
            ),
            CheckboxListTile(
              value: confirmed,
              onChanged: controller.loading.value
                  ? null
                  : (value) => setState(() => confirmed = value ?? false),
              title: const Text(
                'Contrasté este abono en la fuente bancaria independiente',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            ElevatedButton(
              onPressed: controller.loading.value ? null : approve,
              child: const Text('Aprobar abono verificado'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
              ),
            ),
            OutlinedButton(
              onPressed: controller.loading.value ? null : reject,
              child: const Text('Rechazar transferencia'),
            ),
          ],
          if (controller.error.value.isNotEmpty)
            Text(
              controller.error.value,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      );
    }),
  );
}
