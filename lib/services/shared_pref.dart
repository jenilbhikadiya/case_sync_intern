import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/intern.dart';

class SharedPrefService {
  static const String _userKey = 'user';

  static Future<void> saveUser(Intern user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }

  static Future<Intern?> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString(_userKey);

    if (userJson != null) {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      return Intern.fromJson(userMap);
    }
    return null;
  }

  static Future<void> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }
}
