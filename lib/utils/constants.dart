import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intern_side/utils/flavor_config.dart';

const List<String> months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

Color getStatusColor(String status) {
  String normalizedStatus = status.toLowerCase().trim();

  switch (normalizedStatus) {
    case 'completed':
      return Colors.green.shade600;

    case 'allotted':
    case 'alloted':
      return Colors.blue.shade600;

    case 'pending':
      return Colors.orange.shade600;

    case 'reassign':
      return Colors.purple.shade500;

    case 're_alloted':
    case 're-alloted':
      return Colors.teal.shade500;

    default:
      return Colors.grey.shade600;
  }
}

// Get baseUrl from FlavorConfig
String get baseUrl => FlavorConfig.instance.baseUrl;

// Previous baseUrl definitions (kept as comments for reference)
// Production URL
// const baseUrl = "https://pragmanxt.com/case_sync_pro/services/intern/v1/index.php";

// Legacy URL
// const baseUrl = "https://pragmanxt.com/case_sync/services/intern/v1/index.php";

// Test URL
// const baseUrl = "https://pragmanxt.com/case_sync_test/services/intern/v1/index.php";

// Local Development URL
// const baseUrl = "http://192.168.1.129/case_sync/services/intern/v1/index.php";
