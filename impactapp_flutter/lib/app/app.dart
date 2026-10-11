import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import '../shared/theme/app_theme.dart';
import '../shared/theme/theme_controller.dart';

class ImpactApp extends StatelessWidget {
  const ImpactApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        title: 'ImpactApp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,
        getPages: AppPages.pages,
        initialRoute: AppPages.initial,
      ),
    );
  }
}
