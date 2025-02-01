import 'package:flutter/material.dart';

class AppTheme {
  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(40.0),
    ),
    padding: const EdgeInsets.all(15),
  );

  static ButtonStyle getElevatedButtonStyle({Color? backgroundColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40.0),
      ),
      padding: const EdgeInsets.all(15),
    );
  }

  // Text Field Theme
  static InputDecoration textFieldDecoration({
    required String labelText,
    required String hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    );
  }

  static TextStyle titleStyle = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static TextStyle buttonTextStyle = const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  // Custom Colors
  static const Color primaryColor = Colors.black;
  static const Color secondaryColor = Colors.white;
  static const Color errorColor = Colors.red;

  // Refresh Indicator Theme
  static Color getRefreshIndicatorColor(Brightness brightness) {
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  static Color getRefreshIndicatorBackgroundColor() {
    return Colors.white; // Always white background
  }

  // Calendar Theme
  static ThemeData calendarTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Colors.black, // Selected date color
      onPrimary: Colors.white, // Text on selected date
      surface: Colors.white, // Background color
      onSurface: Colors.black, // Default text color
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
    ),
    dialogBackgroundColor: Colors.white,
    buttonTheme: const ButtonThemeData(
      textTheme: ButtonTextTheme.primary,
    ),
  );
}
