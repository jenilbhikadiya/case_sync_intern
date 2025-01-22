import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../models/intern.dart';
import '../services/shared_pref.dart';
import 'appbar/notification_drawer.dart';
import 'appbar/settings_drawer.dart';
import 'cases/case_history.dart';
import 'cases/task_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Intern?> _userData;

  @override
  void initState() {
    super.initState();
    _userData = SharedPrefService.getUser();
  }

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double cardWidth = screenWidth * 0.40;
    double cardHeight = 72;
    double fullCardWidth = screenWidth * 0.93;
    double cardIconPositionX = cardWidth * 0.08;
    double cardIconPositionY = cardHeight * 0.21;
    double cardTextPositionY = cardHeight * 0.57;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        elevation: 0,
        leadingWidth: 86,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/notification.svg',
            width: 35,
            height: 35,
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: const Color.fromRGBO(201, 201, 201, 1),
              builder: (context) => const NotificationDrawer(),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/settings.svg',
                width: 35,
                height: 35,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: const Color.fromRGBO(201, 201, 201, 1),
                  builder: (context) => const SettingsDrawer(),
                );
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<Intern?>(
        future: _userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading user data'));
          } else if (snapshot.hasData && snapshot.data != null) {
            var userData = snapshot.data!;
            String userName = userData.name ?? 'User';

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getGreeting(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 0.95,
                      ),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Color.fromRGBO(37, 27, 70, 1.0),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Cases',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: cardWidth / cardHeight,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildCard(
                          'Task',
                          'assets/icons/unassigned.svg',
                          cardWidth,
                          cardHeight,
                          cardIconPositionX,
                          cardIconPositionY,
                          cardTextPositionY,
                          TaskPage(),
                        ),
                        _buildCard(
                          'Case History',
                          'assets/icons/case_history.svg',
                          cardWidth,
                          cardHeight,
                          cardIconPositionX,
                          cardIconPositionY,
                          cardTextPositionY,
                          const CaseHistoryScreen(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text('User not found'));
          }
        },
      ),
    );
  }

  Widget _buildCard(
    String title,
    String iconPath,
    double cardWidth,
    double cardHeight,
    double iconPositionX,
    double iconPositionY,
    double textPositionY,
    Widget destinationScreen,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Get.to(() => destinationScreen);
          },
          splashColor: Colors.grey.withOpacity(0.2),
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: Stack(
              children: [
                Positioned(
                  left: iconPositionX,
                  top: iconPositionY,
                  child: SvgPicture.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                  ),
                ),
                Positioned(
                  top: textPositionY,
                  left: iconPositionX,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
