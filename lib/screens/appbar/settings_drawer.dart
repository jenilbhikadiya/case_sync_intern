import 'package:flutter/material.dart';
import '../../services/shared_pref.dart';
import '../../models/intern.dart';
import '../forms/login.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  String? userName; // User name from shared preferences
  String? userRole; // User role from shared preferences

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    // Fetch user details from shared preferences
    Intern? user = await SharedPrefService.getUser();
    if (user != null) {
      setState(() {
        userName = user.name; // Update with the user's name
        userRole = user.role; // Update with the user's role
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth,
      height: screenHeight * 0.5,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 1),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Center(
                child: Image.asset(
                  'assets/icons/app_icon.png', // Replace with your actual logo path
                  width: screenWidth * 0.5,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Overlay Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // User Info Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.black,
                      child: Text(
                        userName != null ? userName![0] : '?', // Display the first letter of the name
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName ?? 'Guest', // Fallback to 'Guest' if name is null
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0), // Ensure text is visible
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userRole ?? 'Intern', // Fallback to 'N/A' if role is null
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(179, 0, 0, 0), // Ensure text is visible
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Logout Button
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: Center(
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
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
