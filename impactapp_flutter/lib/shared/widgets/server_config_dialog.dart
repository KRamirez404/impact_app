import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/server_config.dart';
import '../../core/constants/api_constants.dart';
import '../theme/app_theme.dart';

Future<void> mostrarConfiguracionServidor(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _ServerConfigDialog(),
  );
}

class _ServerConfigDialog extends StatefulWidget {
  const _ServerConfigDialog();

  @override
  State<_ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<_ServerConfigDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: ApiConstants.baseUrl,
  );
  String _error = '';
  bool _guardando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final error = ApiConstants.validarBaseUrl(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _guardando = true;
      _error = '';
    });
    await ServerConfig.guardar(_controller.text);
    final resultado = await ServerConfig.verificarConexion();
    if (!mounted) {
      return;
    }
    setState(() {
      _guardando = false;
      _error = resultado ?? '';
    });
    if (resultado == null) {
      Navigator.of(context).pop();
      Get.snackbar(
        'Servidor conectado',
        ApiConstants.baseUrl,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _restaurar() async {
    setState(() {
      _guardando = true;
      _error = '';
    });
    await ServerConfig.restaurar();
    final resultado = await ServerConfig.verificarConexion();
    if (!mounted) {
      return;
    }
    setState(() {
      _guardando = false;
      _controller.text = ApiConstants.baseUrl;
      _error = resultado ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar servidor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            enabled: !_guardando,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'URL del backend',
              hintText: 'http://192.168.1.113:5000/api',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Debe incluir http:// o https:// y terminar en /api',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _error,
              style: const TextStyle(fontSize: 12, color: AppColors.dangerText),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : _restaurar,
          child: const Text('Restaurar'),
        ),
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar y probar'),
        ),
      ],
    );
  }
}
