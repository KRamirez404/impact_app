import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/app.dart';
import 'core/config/server_config.dart';
import 'shared/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FLUTTER_ERROR] ${details.exception}\n${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[UNCAUGHT_ERROR] $error\n$stack');
    return true;
  };

  await GetStorage.init();
  ServerConfig.cargarGuardada();
  Get.put(ThemeController(), permanent: true);
  runApp(const ImpactApp());
}

