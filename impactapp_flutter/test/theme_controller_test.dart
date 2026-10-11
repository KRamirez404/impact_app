import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/shared/theme/theme_controller.dart';

void main() {
  test('themeMode refleja el estado isDark', () {
    final controller = ThemeController();
    expect(controller.isDark.value, isFalse);
    expect(controller.themeMode, ThemeMode.light);

    controller.isDark.value = true;
    expect(controller.themeMode, ThemeMode.dark);
  });
}
