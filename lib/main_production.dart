import 'package:flutter/material.dart';
import 'package:intern_side/utils/flavor_config.dart';
import 'main.dart';

void main() {
  // Set up production configuration
  FlavorConfig(
    flavor: Flavor.production,
    baseUrl: "https://pragmanxt.com/case_sync_pro/services/intern/v1/index.php",
    appName: "Case Sync",
  );

  runApp(const CaseSyncApp());
}
