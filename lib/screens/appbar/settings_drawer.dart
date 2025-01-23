import 'package:flutter/material.dart';
import '../../services/shared_pref.dart';
import '../forms/login.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth,
      height: screenHeight * 0.8,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(201, 201, 201, 1.000),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const Spacer(), // Spacer to push the logout button to the bottom

          Padding(
            padding: const EdgeInsets.only(bottom: 30.0), // Adjust as necessary
            child: ElevatedButton(
              onPressed: () async {
                await SharedPrefService.logOut(); // Call log out function

                // Show snack bar for feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You have been logged out successfully.'),
                  ),
                );

                // Navigate to login screen after successful logout
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
