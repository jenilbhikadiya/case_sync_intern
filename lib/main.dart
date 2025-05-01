import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intern_side/screens/splash_screen.dart';
import 'package:intern_side/utils/flavor_config.dart';

import 'theme_data/app_theme.dart';

void main() {
  // Default to production if no flavor is specified
  FlavorConfig(
    flavor: Flavor.production,
    baseUrl: "https://pragmanxt.com/case_sync_pro/services/intern/v1/index.php",
    appName: "Case Sync",
  );

  runApp(const CaseSyncApp());
}

class CaseSyncApp extends StatelessWidget {
  const CaseSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: FlavorConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
