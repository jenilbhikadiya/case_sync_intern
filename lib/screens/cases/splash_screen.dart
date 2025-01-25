import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../forms/login.dart';
import '../home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');

    if (userData != null) {
      // User is logged in, navigate to HomeScreen
      Get.off(() => const HomeScreen(
            responseBody: [],
          ));
    } else {
      // User is not logged in, navigate to LoginScreen
      Get.off(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(
          243, 243, 243, 1.00), // Background color of splash screen
      body: Center(
        child: SvgPicture.asset(
            'assets/icons/splash_logo.svg'), // Your splash image
      ),
    );
  }
}
