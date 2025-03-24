import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckUpdate {
  static const String apiUrl =
      "https://yourserver.com/version-check"; // API URL (to be added later)
  static const String versionInfoUrl =
      "https://drive.google.com/uc?export=download&id=1_rbzpTvTwLSaLUPDhLC7qLhvsQ7tBIcR"; // Google Drive JSON file ID

  static Future<Map<String, dynamic>?> getDriveFileVersion() async {
    try {
      final response = await http.get(Uri.parse(versionInfoUrl));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching version info from Google Drive: $e");
    }
    return null;
  }

  static Future<void> checkForUpdate(BuildContext context) async {
    String updateUrl = "";
    String latestVersion = "";
    bool forceUpdate = false;

    try {
      final response =
          await http.get(Uri.parse(apiUrl)).timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        latestVersion = data["latest_version"];
        updateUrl = data["update_url"] ?? "";
        forceUpdate = data["force_update"] ?? false;
      }
    } catch (e) {
      print("API not available, checking Google Drive version.");
      final driveData = await getDriveFileVersion();
      if (driveData != null) {
        latestVersion = driveData["latest_version"] ?? "";
        updateUrl = driveData["update_url"] ?? "";
        forceUpdate = driveData["force_update"] ?? false;
      }
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;

    print("Current version: $currentVersion");
    print("Latest version: $latestVersion");

    if (latestVersion.isNotEmpty && currentVersion != latestVersion) {
      showUpdateDialog(context, updateUrl, forceUpdate);
    }
  }

  static void showUpdateDialog(
      BuildContext context, String updateUrl, bool forceUpdate) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate, // Block closing if forced update
      builder: (context) => PopScope(
        canPop: !forceUpdate,
        onPopInvokedWithResult: (didPop, _) {
          if (forceUpdate) {
            SystemNavigator.pop(); // Close the app if forced update
          }
        },
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            "Update Available",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "A new version is available. Please update to continue.",
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Later", style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => launchUrl(Uri.parse(updateUrl)),
              child: Text("Update Now", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (forceUpdate) {
        SystemNavigator.pop(); // Ensure app closes on force update
      }
    });
  }
}
