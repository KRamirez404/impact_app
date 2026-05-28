import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/theme/app_theme.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/setting_item.dart';
import '../widgets/settings/setting_switch.dart';
import '../widgets/settings/danger_item.dart';
import '../widgets/settings/settings_divider.dart';
import '../widgets/settings/settings_footer.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                color: AppColors.settingsBackground,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  children: [
                    SettingsSection(
                      title: 'Cuenta',
                      children: [
                        SettingItem(
                          icon: Icons.lock_outline,
                          title: 'Cambiar contraseña',
                          subtitle: 'Actualiza tu contraseña',
                          onTap: () => Get.snackbar('Info', 'Funcionalidad no implementada',
                              snackPosition: SnackPosition.BOTTOM),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsSection(
                      title: 'Notificaciones',
                      children: [
                        SettingSwitch(
                          icon: Icons.notifications_none,
                          title: 'Notificaciones',
                          subtitle: 'Recibe notificaciones en tu dispositivo',
                          value: controller.notifications,
                          onChanged: controller.toggleNotifications,
                        ),
                        const SettingsDivider(),
                        SettingSwitch(
                          icon: Icons.volunteer_activism_outlined,
                          title: 'Nuevas donaciones',
                          subtitle: 'Alertas sobre donaciones en tus campañas',
                          value: controller.donationAlerts,
                          onChanged: controller.toggleDonationAlerts,
                        ),
                        const SettingsDivider(),
                        SettingSwitch(
                          icon: Icons.chat_bubble_outline,
                          title: 'Comentarios y respuestas',
                          subtitle: 'Notificaciones de interacciones sociales',
                          value: controller.socialNotifications,
                          onChanged: controller.toggleSocialNotifications,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsSection(
                      title: 'Privacidad y seguridad',
                      children: [
                        SettingSwitch(
                          icon: Icons.visibility_outlined,
                          title: 'Mostrar mis donaciones',
                          subtitle: 'Haz visibles tus donaciones públicamente',
                          value: controller.publicDonations,
                          onChanged: controller.togglePublicDonations,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsSection(
                      title: 'Preferencias',
                      children: [
                        SettingSwitch(
                          icon: Icons.brightness_6_outlined,
                          title: 'Modo oscuro',
                          subtitle: 'Cambia la apariencia de la app',
                          value: controller.darkTheme,
                          onChanged: controller.toggleDarkTheme,
                        ),
                        const SettingsDivider(),
                        SettingItem(
                          icon: Icons.language,
                          title: 'Idioma',
                          subtitle: controller.language.value,
                          onTap: () => _showLanguageDialog(controller),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsSection(
                      title: 'Ayuda y acerca de',
                      children: [
                        SettingItem(
                          icon: Icons.description_outlined,
                          title: 'Términos y condiciones',
                          subtitle: 'Lee nuestros términos de uso',
                          onTap: () {},
                        ),
                        const SettingsDivider(),
                        SettingItem(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Política de privacidad',
                          subtitle: 'Conoce cómo protegemos tu información',
                          onTap: () {},
                        ),
                        const SettingsDivider(),
                        SettingItem(
                          icon: Icons.info_outline,
                          title: 'Acerca de ImpactApp',
                          subtitle: 'Versión 1.0.0',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsSection(
                      title: 'Zona de peligro',
                      titleColor: AppColors.dangerSubtitle,
                      children: const [
                        DangerItem(
                          title: 'Eliminar cuenta',
                          subtitle: 'Elimina permanentemente tu cuenta',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SettingsFooter(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16),
      height: 68,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Ajustes',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(SettingsController controller) {
    Get.defaultDialog(
      title: 'Idioma',
      content: Column(
        children: [
          ListTile(title: const Text('Español'), onTap: () { controller.setLanguage('Español'); Get.back(); }),
          ListTile(title: const Text('English'), onTap: () { controller.setLanguage('English'); Get.back(); }),
        ],
      ),
    );
  }
}
