import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  static const String _storageKey = 'dark_theme';
  final GetStorage _storage = GetStorage('settings');

  final isDark = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDark.value = _storage.read<bool>(_storageKey) ?? false;
  }

  ThemeMode get themeMode => isDark.value ? ThemeMode.dark : ThemeMode.light;

  void setDark(bool value) {
    isDark.value = value;
    _storage.write(_storageKey, value);
  }

  void toggle() => setDark(!isDark.value);
}
