import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _darkTheme = false;
  String _language = 'Español';

  void _chooseLanguage() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Idioma'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Español'),
            child: const Text('Español'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'English'),
            child: const Text('English'),
          ),
        ],
      ),
    );
    if (choice != null) setState(() => _language = choice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notificaciones'),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
            secondary: const Icon(Icons.notifications),
          ),
          SwitchListTile(
            title: const Text('Tema oscuro'),
            value: _darkTheme,
            onChanged: (v) => setState(() => _darkTheme = v),
            secondary: const Icon(Icons.brightness_6),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Idioma'),
            subtitle: Text(_language),
            onTap: _chooseLanguage,
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Cambiar contraseña'),
            onTap: () => Get.snackbar('Info', 'Funcionalidad no implementada', snackPosition: SnackPosition.BOTTOM),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Eliminar cuenta', style: TextStyle(color: Colors.red)),
            onTap: () => Get.defaultDialog(
              title: 'Confirmar',
              middleText: '¿Deseas eliminar tu cuenta? Esta acción no se puede deshacer.',
              textCancel: 'Cancelar',
              textConfirm: 'Eliminar',
              confirmTextColor: Colors.white,
              onConfirm: () {
                Get.back();
                Get.snackbar('Eliminado', 'Cuenta marcada para eliminación', snackPosition: SnackPosition.BOTTOM);
              },
            ),
          ),
        ],
      ),
    );
  }
}
