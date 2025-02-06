import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intern_side/models/intern.dart';

import '../../components/basicUIcomponent.dart';
import '../../services/api_service.dart';
import '../../services/shared_pref.dart';
import '../../utils/validator.dart';
import '../home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateUserID(String? value) {
    return validateAndTrimField(value, 'User ID');
  }

  String? _validatePassword(String? value) {
    return validateAndTrimField(value, 'Password');
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      try {
        // Call the login API
        var response = await ApiService.loginUser(email, password);
        print(response['success']);

        // Check if the login was successful
        if (response['success'] == true) {
          var data = response['data'];

          // If the data is a list, we take the first user; otherwise, treat it as a map.
          if (data is List && data.isNotEmpty) {
            // Cast the first item in the list to Map<String, dynamic>
            Map<String, dynamic> userJson =
                (data[0] as Map).cast<String, dynamic>();
            Intern intern = Intern.fromJson(userJson);
            await SharedPrefService.saveUser(intern);
          } else if (data is Map) {
            // If it's a map, cast it to Map<String, dynamic>
            Map<String, dynamic> userJson = (data).cast<String, dynamic>();
            Intern intern = Intern.fromJson(userJson);
            await SharedPrefService.saveUser(intern);
          }

          Get.offAll(() => const HomeScreen());
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const HomeScreen()));
        } else {
          if (response['message'] == false) {
            Get.snackbar('Error',
                'Login failed because of no Internet Connection. Check the Internet Connection and try again.');
            return;
          } else {
            Get.snackbar('Login failed', 'Incorrect Username or Password');
          }
        }
      } catch (e) {
        print('An error occurred: $e');
        Get.snackbar('Error', 'Login failed, please try again.');
      } finally {
        setState(() {
          _isLoading = false;
        });
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
                // App Icon (Logo)
                SvgPicture.asset('assets/icons/casesync_text.svg'),
                const SizedBox(height: 50),
                // User ID Field
                TextFormField(
                  controller: _emailController,
                  decoration: AppTheme.textFieldDecoration(
                    labelText: 'User ID',
                    hintText: 'Your email',
                  ),
                  validator: _validateUserID,
                ),
                const SizedBox(height: 20),
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: AppTheme.textFieldDecoration(
                    labelText: 'Password',
                    hintText: 'Password',
                  ).copyWith(
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
                  validator: _validatePassword,
                ),
                const SizedBox(height: 100),
                // Login Button
                SizedBox(
                  width: screenWidth * 0.5,
                  height: 70,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: AppTheme.elevatedButtonStyle,
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
                // Error Message
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
