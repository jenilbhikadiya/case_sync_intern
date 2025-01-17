import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  // Save username to SharedPreferences
  static Future<void> setUser({required String username}) async {
    SharedPreferences sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setString('username', username);
  }

  // Retrieve username from SharedPreferences
  static Future<String?> getUsername() async {
    SharedPreferences sharedPref = await SharedPreferences.getInstance();
    return sharedPref.getString('username');
  }

  // Save Gmail to SharedPreferences
  static Future<void> setGmail({required String gmail}) async {
    SharedPreferences sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setString('gmail', gmail);
  }

  // Retrieve Gmail from SharedPreferences
  static Future<String?> getGmail() async {
    SharedPreferences sharedPref = await SharedPreferences.getInstance();
    return sharedPref.getString('gmail');
  }

  // Save imageUrl to SharedPreferences
  static Future<void> setImageUrl({required String imageUrl}) async {
    SharedPreferences sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setString('imageUrl', imageUrl);
  }

  // Retrieve imageUrl from SharedPreferences
  static Future<String?> getImageUrl() async {
    SharedPreferences sharedPref = await SharedPreferences.getInstance();
    return sharedPref.getString("imageUrl");
  }

  // Clear all user data from SharedPreferences (Logout functionality)
  static Future<void> logOut() async {
    SharedPreferences sharedPref = await SharedPreferences.getInstance();

    // Clear all stored data in SharedPreferences
    await sharedPref.clear();
  }
}
