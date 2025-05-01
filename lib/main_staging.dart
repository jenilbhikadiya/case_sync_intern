import 'package:flutter/material.dart';
import 'package:intern_side/utils/flavor_config.dart';
import 'main.dart';

void main() {
  // Set up staging configuration
  FlavorConfig(
    flavor: Flavor.staging,
    baseUrl:
        "https://pragmanxt.com/case_sync_test/services/intern/v1/index.php",
    appName: "Case Sync Test",
  );

  runApp(const CaseSyncApp());
}
