import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'appbar/notification_drawer.dart';
import 'appbar/settings_drawer.dart';
import 'cases/case_history.dart';
import 'cases/task_page.dart';
class HomeScreen extends StatelessWidget {
  final List<dynamic> responseBody;

  const HomeScreen({super.key, required this.responseBody});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    List<dynamic> userList = responseBody;
    Map<String, dynamic> userData = userList.isNotEmpty ? userList[0] : {};
    String userName = userData['name'] ?? 'User';

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
        leadingWidth: 56 + 30,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/notification.svg',
            width: 35,
            height: 35,
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              scrollControlDisabledMaxHeightRatio: 5 / 6,
              backgroundColor: Color.fromRGBO(201, 201, 201, 1),
              builder: (context) => const NotificationDrawer(),
            );
          },
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/settings.svg',
                width: 35,
                height: 35,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  scrollControlDisabledMaxHeightRatio: 5 / 6,
                  backgroundColor: Color.fromRGBO(201, 201, 201, 1),
                  builder: (context) => const SettingsDrawer(),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
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
                  color: Color.fromRGBO(37, 27, 70, 1.000),
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 20),

              // "Cases" section
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
                    context,
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
                    context,
                    CaseHistoryScreen(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),

              const SizedBox(height: 10),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Responsive card widget with navigation
  Widget _buildCard(
    String title,
    String iconPath,
    double cardWidth,
    double cardHeight,
    double iconPositionX,
    double iconPositionY,
    double textPositionY,
    BuildContext context,
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
          borderRadius: BorderRadius.circular(20), // Ensures ripple is confined
          onTap: () {
            // Navigate to the target screen when card is tapped
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destinationScreen),
            );
          },
          splashColor:
              Colors.grey.withOpacity(0.2), // Optional: Custom splash color
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
