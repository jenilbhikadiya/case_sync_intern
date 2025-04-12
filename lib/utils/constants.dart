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

/// Returns a distinct color based on the task status.
Color getStatusColor(String status) {
  // Normalize the status string for reliable comparison
  String normalizedStatus = status.toLowerCase().trim();

  switch (normalizedStatus) {
    case 'completed':
      // A clear, positive green
      return Colors.green.shade600;

    case 'allotted': // Handle both spellings if necessary
    case 'alloted':
      // A standard, active blue - indicates assigned/in progress
      return Colors.blue.shade600; // Changed from blueAccent

    case 'pending':
      // A warm orange - indicates waiting or needs action
      return Colors
          .orange.shade600; // Changed from shade400 for better visibility

    case 'reassign':
      // A distinct purple - indicates a specific action/request state
      // Differentiates it from standard 'allotted' blue
      return Colors.purple.shade500; // Changed from blue

    case 're_alloted': // Handles 're_alloted' specifically
    case 're-alloted': // Also handle hyphen variation if possible
      // A teal/cyan color - distinct from initial blue and purple,
      // might indicate it's been processed/returned/assigned again
      return Colors.teal.shade500; // Changed from red

    // Add other specific statuses if you have them:
    // case 'overdue':
    //   return Colors.red.shade700; // Use red for critical states
    // case 'in-progress': // If different from 'allotted'
    //    return Colors.lightBlue.shade600;

    default:
      // A neutral grey for unknown or less important statuses
      return Colors.grey.shade600; // Slightly darker grey
  }
}

// const baseUrl =
// "https://pragmanxt.com/case_sync_pro/services/intern/v1/index.php";

// const baseUrl = "https://pragmanxt.com/case_sync/services/intern/v1/index.php";

const baseUrl =
    "https://pragmanxt.com/case_sync_test/services/intern/v1/index.php";

// const baseUrl = "http://192.168.1.129/case_sync/services/intern/v1/index.php";
