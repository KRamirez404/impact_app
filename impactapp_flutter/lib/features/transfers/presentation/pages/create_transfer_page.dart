import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../controllers/transfer_controller.dart';
import '../controllers/transfer_form_validator.dart';

class CreateTransferPage extends StatefulWidget {
  const CreateTransferPage({super.key});

  @override
  State<CreateTransferPage> createState() => _CreateTransferPageState();
}

class _CreateTransferPageState extends State<CreateTransferPage> {
  final controller = Get.find<TransferController>();
  final amountController = TextEditingController();
  final referenceController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime transferDate = DateTime.now();
  String? receiptPath;
  String? receiptName;
  bool initialized = false;

  int get campaignId => int.tryParse(Get.parameters['id'] ?? '') ?? 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      controller.loadAccount(campaignId);
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    referenceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickReceipt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final file = result?.files.single;
    if (file == null) return;
    if (file.path == null) {
      controller.error.value =
          'No fue posible leer el comprobante seleccionado';
      return;
    }
    if (file.size <= 0 || file.size > 8 * 1024 * 1024) {
      controller.error.value = 'El comprobante debe pesar máximo 8 MiB';
      return;
    }
    setState(() {
      receiptPath = file.path;
      receiptName = file.name;
    });
  }

  Future<void> submit() async {
    final validation = TransferFormValidator.validate(
      amount: amountController.text,
      reference: referenceController.text,
      transferDate: transferDate,
    );
    if (validation.error != null) {
      controller.error.value = validation.error!;
      return;
    }
    if (receiptPath == null) {
      controller.error.value = 'Selecciona el comprobante de la transferencia';
      return;
    }
    final account = controller.account.value;
    if (account == null || !account.estaVerificada) {
      controller.error.value = 'La campaña no tiene una cuenta verificada';
      return;
    }
    var transfer = controller.current.value;
    if (transfer == null || transfer.idCampania != campaignId) {
      transfer = await controller.register({
        'id_campania': campaignId,
        'id_cuenta_recaudo': account.idCuentaRecaudo,
        'monto': validation.amountForApi,
        'moneda': 'COP',
        'referencia_bancaria': validation.reference,
        'fecha_transferencia': validation.dateForApi,
        'descripcion': descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      });
    }
    if (transfer == null) return;
    final uploaded = await controller.upload(receiptPath!, resubmit: false);
    if (uploaded) {
      Get.offNamed('${AppRoutes.transferDetail}/${transfer.idTransferencia}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transferencia bancaria')),
      body: Obx(() {
        final account = controller.account.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (controller.loading.value && account == null)
              const Center(child: CircularProgressIndicator())
            else if (controller.error.value.isNotEmpty && account == null)
              _ErrorCard(
                message: controller.error.value,
                onRetry: () => controller.loadAccount(campaignId),
              )
            else if (account != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cuenta de recaudo verificada',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        '${account.banco} · ${account.tipoCuenta}',
                      ),
                      SelectableText(account.numeroCuenta),
                      SelectableText(account.titular),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monto transferido (COP)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: referenceController,
                decoration: const InputDecoration(
                  labelText: 'Referencia bancaria',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de transferencia'),
                subtitle: Text(
                  '${transferDate.day}/${transferDate.month}/${transferDate.year}',
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDate: transferDate,
                  );
                  if (selected != null) setState(() => transferDate = selected);
                },
              ),
              TextField(
                controller: descriptionController,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Descripción opcional',
                ),
              ),
              OutlinedButton.icon(
                onPressed: controller.loading.value ? null : pickReceipt,
                icon: const Icon(Icons.attach_file),
                label: Text(receiptName ?? 'Seleccionar comprobante'),
              ),
              if (controller.current.value != null &&
                  controller.current.value!.comprobante == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'La transferencia ya fue registrada. Reintenta únicamente la carga del comprobante.',
                  ),
                ),
              if (controller.error.value.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  controller.error.value,
                  style: const TextStyle(color: Color(0xFFD32F2F)),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.loading.value ? null : submit,
                child: controller.loading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrar transferencia'),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
