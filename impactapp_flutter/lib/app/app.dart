import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import '../shared/theme/app_theme.dart';

class ImpactApp extends StatelessWidget {
  const ImpactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ImpactApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      getPages: AppPages.pages,
      initialRoute: AppPages.initial,
    );
  }
}

