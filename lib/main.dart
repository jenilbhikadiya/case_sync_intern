import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intern_side/screens/cases/splash_screen.dart';
import 'theme_data/app_theme.dart';

void main() {
  runApp(const CaseSyncApp());
}

class CaseSyncApp extends StatelessWidget {
  const CaseSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
