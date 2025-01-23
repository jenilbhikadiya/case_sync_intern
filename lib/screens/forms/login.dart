import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../models/intern.dart';
import '../../services/api_service.dart';
import '../../services/shared_pref.dart';
import '../home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  String _errorMessage = '';
  bool _isLoading = false; // To handle loading state

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final RegExp emailRegExp = RegExp(
      r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
    );
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      String email = _emailController.text;
      String password = _passwordController.text;

      try {
        // Call the login API
        final response = await ApiService.loginUser(email, password);
        print("Variable Response: ${response['data']}");

        // Check if the login was successful
        if (response['success'] == true) {
          var data = response['data'];

          // If the data is a list, we take the first user; otherwise, treat it as a map.
          if (data is List && data.isNotEmpty) {
            // Cast the first item in the list to Map<String, dynamic>
            Map<String, dynamic> userJson =
                (data as Map).cast<String, dynamic>();
            Intern intern = Intern.fromJson(userJson);
            await SharedPrefService.saveUser(intern);
          } else if (data is Map) {
            // If it's a map, cast it to Map<String, dynamic>
            Map<String, dynamic> userJson = (data).cast<String, dynamic>();
            Intern intern = Intern.fromJson(userJson);
            await SharedPrefService.saveUser(intern);
          }

          // Navigate to the home screen
          Get.offAll(() => const HomeScreen());
        } else {
          // Handle login failure
          Get.snackbar('Login Error', response['message']);
        }
      } catch (e) {
        print('An error occurred: $e');
        Get.snackbar('Error', 'Login failed, please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 16, 30, 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.25),
                SvgPicture.asset('assets/icons/casesync_text.svg'),
                const SizedBox(height: 50),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'User ID',
                    hintText: 'Your email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 100),
                SizedBox(
                  width: screenWidth * 0.5,
                  height: 70,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
