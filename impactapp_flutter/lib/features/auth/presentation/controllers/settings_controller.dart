import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final _storage = GetStorage('settings');

  final notifications = true.obs;
  final donationAlerts = true.obs;
  final socialNotifications = true.obs;
  final publicDonations = false.obs;
  final darkTheme = false.obs;
  final language = 'Español'.obs;

  @override
  void onInit() {
    super.onInit();
    notifications.value = _storage.read('notifications') ?? true;
    donationAlerts.value = _storage.read('donation_alerts') ?? true;
    socialNotifications.value = _storage.read('social_notifications') ?? true;
    publicDonations.value = _storage.read('public_donations') ?? false;
    darkTheme.value = _storage.read('dark_theme') ?? false;
    language.value = _storage.read('language') ?? 'Español';
  }

  void toggleNotifications(bool value) {
    notifications.value = value;
    _storage.write('notifications', value);
  }

  void toggleDonationAlerts(bool value) {
    donationAlerts.value = value;
    _storage.write('donation_alerts', value);
  }

  void toggleSocialNotifications(bool value) {
    socialNotifications.value = value;
    _storage.write('social_notifications', value);
  }

  void togglePublicDonations(bool value) {
    publicDonations.value = value;
    _storage.write('public_donations', value);
  }

  void toggleDarkTheme(bool value) {
    darkTheme.value = value;
    _storage.write('dark_theme', value);
  }

  void setLanguage(String lang) {
    language.value = lang;
    _storage.write('language', lang);
  }
}
