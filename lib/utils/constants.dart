import 'dart:ui';

import 'package:flutter/material.dart';

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
  switch (status.toLowerCase()) {
    case 'completed':
      return Colors.green;
    case 'allotted' || 'alloted':
      return Colors.blueAccent;
    case 'pending':
      return Colors.yellow;
    case 'reassign':
      return Colors.lightBlue;
    case 're_alloted':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

const baseUrl =
"https://pragmanxt.com/case_sync_pro/services/intern/v1/index.php";

// const baseUrl = "https://pragmanxt.com/case_sync/services/intern/v1/index.php";

// const baseUrl = "http://192.168.1.129/case_sync/services/intern/v1/index.php";
