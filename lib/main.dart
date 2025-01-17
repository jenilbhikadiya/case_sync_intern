import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme_data/app_theme.dart';

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
