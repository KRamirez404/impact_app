import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/theme/app_theme.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

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
                    _buildAccountSection(controller),
                    const SizedBox(height: 16),
                    _buildNotificationsSection(controller),
                    const SizedBox(height: 16),
                    _buildPrivacySection(controller),
                    const SizedBox(height: 16),
                    _buildPreferencesSection(controller),
                    const SizedBox(height: 16),
                    _buildHelpSection(),
                    const SizedBox(height: 16),
                    _buildDangerZone(),
                    const SizedBox(height: 16),
                    _buildFooter(),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Ajustes',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(SettingsController controller) {
    return _buildSection(
      title: 'Cuenta',
      children: [
        _buildSettingItem(
          icon: Icons.lock_outline,
          title: 'Cambiar contraseña',
          subtitle: 'Actualiza tu contraseña',
          onTap: () => Get.snackbar(
            'Info',
            'Funcionalidad no implementada',
            snackPosition: SnackPosition.BOTTOM,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(SettingsController controller) {
    return _buildSection(
      title: 'Notificaciones',
      children: [
        _buildSettingSwitch(
          icon: Icons.notifications_none,
          title: 'Notificaciones',
          subtitle: 'Recibe notificaciones en tu dispositivo',
          value: controller.notifications,
          onChanged: controller.toggleNotifications,
        ),
        _buildDivider(),
        _buildSettingSwitch(
          icon: Icons.volunteer_activism_outlined,
          title: 'Nuevas donaciones',
          subtitle: 'Alertas sobre donaciones en tus campañas',
          value: controller.donationAlerts,
          onChanged: controller.toggleDonationAlerts,
        ),
        _buildDivider(),
        _buildSettingSwitch(
          icon: Icons.chat_bubble_outline,
          title: 'Comentarios y respuestas',
          subtitle: 'Notificaciones de interacciones sociales',
          value: controller.socialNotifications,
          onChanged: controller.toggleSocialNotifications,
        ),
      ],
    );
  }

  Widget _buildPrivacySection(SettingsController controller) {
    return _buildSection(
      title: 'Privacidad y seguridad',
      children: [
        _buildSettingSwitch(
          icon: Icons.visibility_outlined,
          title: 'Mostrar mis donaciones',
          subtitle: 'Haz visibles tus donaciones públicamente',
          value: controller.publicDonations,
          onChanged: controller.togglePublicDonations,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(SettingsController controller) {
    return _buildSection(
      title: 'Preferencias',
      children: [
        _buildSettingSwitch(
          icon: Icons.brightness_6_outlined,
          title: 'Modo oscuro',
          subtitle: 'Cambia la apariencia de la app',
          value: controller.darkTheme,
          onChanged: controller.toggleDarkTheme,
        ),
        _buildDivider(),
        _buildSettingItem(
          icon: Icons.language,
          title: 'Idioma',
          subtitle: controller.language.value,
          onTap: () => _showLanguageDialog(controller),
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return _buildSection(
      title: 'Ayuda y acerca de',
      children: [
        _buildSettingItem(
          icon: Icons.description_outlined,
          title: 'Términos y condiciones',
          subtitle: 'Lee nuestros términos de uso',
          onTap: () {},
        ),
        _buildDivider(),
        _buildSettingItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Política de privacidad',
          subtitle: 'Conoce cómo protegemos tu información',
          onTap: () {},
        ),
        _buildDivider(),
        _buildSettingItem(
          icon: Icons.info_outline,
          title: 'Acerca de ImpactApp',
          subtitle: 'Versión 1.0.0',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return _buildSection(
      title: 'Zona de peligro',
      titleColor: AppColors.dangerSubtitle,
      children: [
        _buildDangerItem(
          title: 'Eliminar cuenta',
          subtitle: 'Elimina permanentemente tu cuenta',
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Text(
            'ImpactApp © 2026',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.footerText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Donaciones con transparencia y confianza',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.footerSubtitle,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    Color? titleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.3,
              color: titleColor ?? AppColors.sectionHeader,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 1.18),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildIconContainer(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.chevronColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required RxBool value,
    required Function(bool) onChanged,
  }) {
    return Obx(() => Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildIconContainer(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value.value,
              onChanged: onChanged,
              activeThumbColor: AppColors.switchOn,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: AppColors.switchOff,
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildDangerItem({
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () => Get.defaultDialog(
        title: 'Confirmar',
        middleText: '¿Deseas eliminar tu cuenta? Esta acción no se puede deshacer.',
        textCancel: 'Cancelar',
        textConfirm: 'Eliminar',
        cancelTextColor: AppColors.subtitle,
        confirmTextColor: Colors.white,
        buttonColor: AppColors.dangerText,
        onConfirm: () {
          Get.back();
          Get.snackbar('Eliminado', 'Cuenta marcada para eliminación', snackPosition: SnackPosition.BOTTOM);
        },
      ),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.dangerIconBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.dangerText,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Eliminar cuenta',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.dangerText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
              color: AppColors.dangerSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.dangerSubtitle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.iconGradientStart, AppColors.iconGradientEnd],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        color: AppColors.gradientStart,
        size: 20,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.cardBorder,
    );
  }

  void _showLanguageDialog(SettingsController controller) {
    Get.defaultDialog(
      title: 'Idioma',
      content: Column(
        children: [
          _languageOption('Español', controller),
          _languageOption('English', controller),
        ],
      ),
    );
  }

  Widget _languageOption(String lang, SettingsController controller) {
    return ListTile(
      title: Text(lang),
      onTap: () {
        controller.setLanguage(lang);
        Get.back();
      },
    );
  }
}
