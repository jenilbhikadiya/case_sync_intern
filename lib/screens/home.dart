import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/models/notification_item.dart';
import 'package:intern_side/services/case_services.dart';
import 'package:intern_side/utils/constants.dart';

import '../models/intern.dart';
import '../services/shared_pref.dart';
import 'Case_History/case_history.dart';
import 'Tasks/task_page.dart';
import 'appbar/notification_drawer.dart';
import 'appbar/settings_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  StreamSubscription<List<ConnectivityResult>>? subscription;
  bool isInternetConnected = true;
  ValueNotifier<int> caseCount = ValueNotifier<int>(-1);
  ValueNotifier<int> taskCount = ValueNotifier<int>(-1);
  ValueNotifier<int> todays_case_count = ValueNotifier<int>(-1);
  ValueNotifier<int> counters_count = ValueNotifier<int>(-1);

  String errorMessage = '';
  late Intern? user;
  ValueNotifier<List<NotificationItem>> taskList =
      ValueNotifier<List<NotificationItem>>([]);

  @override
  void initState() {
    super.initState();
    initialisation();
  }

  Future<void> checkInternetConnection() async {}

  Future<void> initialisation() async {
    taskList.value = await fetchInternData();
  }

  Future<List<NotificationItem>> fetchInternData() async {
    user = await SharedPrefService.getUser();
    print("UserId: ${user?.id}");
    if (user != null) {
      print("Fetching");
      taskList.value = await fetchCaseAndTaskCounters(user!.id);
      print("Fetched: ${taskList.value}");
      populateCaseData(user!.id);

      return taskList.value;
    }
    return [];
  }

  Future<List<NotificationItem>> fetchCaseAndTaskCounters(
      String internId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/notification'),
          body: {'intern_id': internId});

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          taskList.value = (responseData['data'] as List)
              .map((item) => NotificationItem.fromJson(item))
              .toList();

          caseCount.value =
              int.parse(responseData['counters'][0]['case_count']);
          taskCount.value =
              int.parse(responseData['counters'][1]['task_count']);
          todays_case_count.value =
              int.parse(responseData['counters'][2]['todays_case_count']);
          counters_count.value =
              int.parse(responseData['counters'][3]['counters_count']);

          return taskList.value;
        } else {
          errorMessage = responseData['message'];
        }
      } else {
        errorMessage = "Failed to fetch data.";
      }
    } catch (e) {
      errorMessage = "Error: $e";
    }
    return [];
  }

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth * 0.40;
    double cardHeight = 72;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      appBar: isInternetConnected
          ? AppBar(
              surfaceTintColor: Colors.transparent,
              backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
              elevation: 0,
              leading: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Stack(
                    children: [
                      IconButton(
                        icon: SvgPicture.asset('assets/icons/notification.svg',
                            width: 35, height: 35),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor:
                                const Color.fromRGBO(201, 201, 201, 1),
                            builder: (context) => NotificationDrawer(
                              taskItem: taskList.value,
                              onRefresh: fetchInternData,
                            ),
                          );
                        },
                      ),
                      ValueListenableBuilder<List<NotificationItem>>(
                        valueListenable: taskList,
                        builder: (context, cases, child) {
                          return cases.isNotEmpty
                              ? // Show badge only if there are notifications
                              Positioned(
                                  right: 5,
                                  top: -3,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Color(0xFF292D32),
                                        width: 2,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Text(
                                      taskList.value.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              : const SizedBox();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: IconButton(
                    icon: SvgPicture.asset('assets/icons/settings.svg',
                        width: 35, height: 35),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color.fromRGBO(201, 201, 201, 1),
                        builder: (context) => const SettingsDrawer(),
                      );
                    },
                  ),
                ),
              ],
            )
          : AppBar(),
      body: isInternetConnected
          ? Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<Intern?>(
                      future: SharedPrefService.getUser(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator(
                              color: Colors.black);
                        } else if (snapshot.hasError) {
                          return const Text('Error loading user data');
                        } else if (!snapshot.hasData || snapshot.data == null) {
                          return const Text('No user data available');
                        }

                        Intern user = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(getGreeting(),
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black)),
                            Text(
                              user.name,
                              style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: Color.fromRGBO(37, 27, 70, 1.0)),
                            ),
                            const Text(
                              'Notice',
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
                                  title: 'Case Counter',
                                  iconPath: 'assets/icons/case_counter.svg',
                                  cardWidth: cardWidth,
                                  cardHeight: cardHeight,
                                  destinationScreen: TaskPage(),
                                  counterNotifier: counters_count,
                                  shouldDisplayCounter: true,
                                ),
                                _buildCard(
                                  title: 'Today\'s Cases',
                                  iconPath: 'assets/icons/cases_today.svg',
                                  cardWidth: cardWidth,
                                  cardHeight: cardHeight,
                                  destinationScreen: TaskPage(),
                                  counterNotifier: todays_case_count,
                                  shouldDisplayCounter: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text('Cases',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
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
                                  title: 'Tasks',
                                  iconPath: 'assets/icons/tasks.svg',
                                  cardWidth: cardWidth,
                                  cardHeight: cardHeight,
                                  destinationScreen: const TaskPage(),
                                  counterNotifier: taskCount,
                                ),
                                _buildCard(
                                  title: 'Case History',
                                  iconPath: 'assets/icons/case_history.svg',
                                  cardWidth: cardWidth,
                                  cardHeight: cardHeight,
                                  destinationScreen:
                                      CaseHistoryScreen(internId: user.id),
                                  counterNotifier: caseCount,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          : GestureDetector(
              onLongPress: () {
                initState();
              },
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No Internet Connected.'),
                    Text('Long Press the Screen to try again.')
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCard({
    required String title,
    required String iconPath,
    required double cardWidth,
    required double cardHeight,
    required Widget destinationScreen,
    bool shouldDisplayCounter = true,
    required ValueNotifier<int> counterNotifier,
  }) {
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
          onTap: () async {
            HapticFeedback.mediumImpact();
            var result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destinationScreen),
            );

            if (result == false) {
              fetchCaseAndTaskCounters(user!.id);
            }
          },
          child: Stack(
            children: [
              // Card Content (Icon + Title)
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 4),
                          SvgPicture.asset(iconPath, width: 30, height: 30),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Badge positioned at the top-right corner
              if (shouldDisplayCounter)
                Positioned(
                  top: ((cardHeight / 2) - 19),
                  right: 8,
                  child: _BadgeCounter(counterNotifier: counterNotifier),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeCounter extends StatelessWidget {
  final ValueNotifier<int> counterNotifier;

  const _BadgeCounter({required this.counterNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: counterNotifier,
      builder: (context, value, child) {
        return Container(
          width: 40, // Fixed size for uniformity
          height: 40,
          decoration: BoxDecoration(
            color: value == -1 ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(30), // Circular shape
            border: Border.all(
              color: Colors.black,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: value == -1
              ? SizedBox(
                  width: 18,
                  height: 6,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white,
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              : Text(
                  "${value == -2 ? "</>" : value}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
        );
      },
    );
  }
}
