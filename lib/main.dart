import 'package:flutter/material.dart';
import 'package:intern_side/screens/cases/theme_data/app_theme.dart';
import 'screens/cases/splash_screen.dart';

void main() {
  runApp(const CaseSyncApp());
}

class CaseSyncApp extends StatelessWidget {
  const CaseSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
