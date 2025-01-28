import 'package:flutter/material.dart';

class AppTheme {
  // Method to get the light theme data (black and white)
  static ThemeData get theme {
    return ThemeData(
      // Set the primary colors
      primaryColor: Colors.black,
      scaffoldBackgroundColor: Color.fromRGBO(243, 243, 243, 1.0),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.black,
        selectionColor: Colors.black.withOpacity(.15),
        selectionHandleColor: Colors.black
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black, // Button background color
          foregroundColor: Colors.white, // Button text color
          textStyle: const TextStyle(fontSize: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
      ),

      // Input field theme
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: Colors.black),
        hintStyle: TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: Colors.black,
        size: 24,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.black, fontSize: 16),
        displayMedium: TextStyle(color: Colors.black, fontSize: 14),
        headlineLarge: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Floating Action Button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      // Checkbox and Switch theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(Colors.black),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.black),
        trackColor: WidgetStateProperty.all(Colors.black54),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
        elevation: 2,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: Colors.black,
        thickness: 1,
      ),
    );
  }
}
