import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/transfer_controller.dart';
import '../widgets/transfer_status_chip.dart';

class TransferDetailPage extends StatefulWidget {
  const TransferDetailPage({super.key});

  @override
  State<TransferDetailPage> createState() => _TransferDetailPageState();
}

class _TransferDetailPageState extends State<TransferDetailPage> {
  final controller = Get.find<TransferController>();
  int get transferId => int.tryParse(Get.parameters['id'] ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    controller.loadTransfer(transferId);
  }

  Future<void> resubmit() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final file = result?.files.single;
    if (file?.path == null) return;
    if (file!.size <= 0 || file.size > 8 * 1024 * 1024) {
      controller.error.value = 'El comprobante debe pesar máximo 8 MiB';
      return;
    }
    await controller.upload(file.path!, resubmit: true);
  }

  Future<void> download() async {
    final bytes = await controller.download();
    final transfer = controller.current.value;
    if (bytes == null || transfer == null) return;
    final extension = switch (transfer.comprobante?.mime) {
      'application/pdf' => 'pdf',
      'image/png' => 'png',
      _ => 'jpg',
    };
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar comprobante',
      fileName: 'comprobante_${transfer.idTransferencia}.$extension',
      bytes: bytes,
    );
    if (path != null) {
      Get.snackbar(
        'Comprobante guardado',
        path,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de transferencia')),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    transfer.campaniaTitulo,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TransferStatusChip(status: transfer.estado),
              ],
            ),
            const SizedBox(height: 16),
            _data(
              'Monto',
              NumberFormat.currency(
                locale: 'es_CO',
                symbol: r'$ ',
                decimalDigits: 2,
              ).format(transfer.monto),
            ),
            _data('Referencia bancaria', transfer.referenciaBancaria),
            _data('Fecha', transfer.fechaTransferencia),
            _data(
              'Cuenta',
              '${transfer.cuenta.banco} · ${transfer.cuenta.numeroCuenta}',
            ),
            if (transfer.descripcion?.isNotEmpty == true)
              _data('Descripción', transfer.descripcion!),
            if (transfer.motivoRechazo?.isNotEmpty == true)
              Card(
                color: const Color(0xFFFFF1F2),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Motivo del rechazo: ${transfer.motivoRechazo}'),
                ),
              ),
            if (controller.error.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  controller.error.value,
                  style: const TextStyle(color: Color(0xFFD32F2F)),
                ),
              ),
            if (transfer.comprobante != null)
              OutlinedButton.icon(
                onPressed: controller.loading.value ? null : download,
                icon: const Icon(Icons.download),
                label: const Text('Descargar comprobante'),
              ),
            if (transfer.puedeReenviar)
              ElevatedButton.icon(
                onPressed: controller.loading.value ? null : resubmit,
                icon: const Icon(Icons.upload_file),
                label: const Text('Enviar nuevo comprobante'),
              ),
          ],
        );
      }),
    );
  }

  Widget _data(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF717182))),
        SelectableText(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
