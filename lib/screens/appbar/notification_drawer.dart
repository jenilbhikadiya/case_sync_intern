import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intern_side/models/notification_item.dart';

import 'notification_card.dart';

class NotificationDrawer extends StatefulWidget {
  final List<NotificationItem> taskItem;
  final Future<List<NotificationItem>> Function() onRefresh;
  const NotificationDrawer(
      {super.key, required this.taskItem, required this.onRefresh});

  @override
  State<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends State<NotificationDrawer> {
  late List<NotificationItem> taskItem;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    taskItem = widget.taskItem;
  }

  @override
  Widget build(BuildContext context) {
    void removeTaskItem(NotificationItem task) {
      setState(() {
        print("Removed: ${task.caseNo}");
        taskItem.removeWhere((c) => c.typeId == task.typeId);
      });
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.8,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Title Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Notification Center',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(thickness: 1, height: 1, color: Colors.black54),

          // TaskItem List or Empty State
          Expanded(
            child: taskItem.isEmpty
                ? (isLoading)
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.black,
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Long Press Here to Refresh 👇🏼',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              GestureDetector(
                                  onLongPress: () async {
                                    HapticFeedback.selectionClick();
                                    print("Long press detected");
                                    setState(() {
                                      isLoading = true;
                                    });
                                    List<NotificationItem> tempList =
                                        await widget.onRefresh();
                                    setState(() {
                                      taskItem = tempList;
                                      isLoading = false;
                                    });
                                  },
                                  child: Container(
                                    width: screenHeight * 0.3,
                                    height: screenHeight * 0.3,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(
                                          screenHeight * 0.3),
                                    ),
                                  ))
                            ],
                          ),
                        ),
                      )
                : RefreshIndicator(
                    color: Colors.black,
                    onRefresh: () async {
                      List<NotificationItem> tempList =
                          await widget.onRefresh();
                      setState(() {
                        taskItem = tempList;
                      });
                      print("Refreshed: ${taskItem.length}");
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: taskItem.length,
                      itemBuilder: (context, index) {
                        return NotificationCard(
                          taskItem: taskItem[index],
                          onDismiss: removeTaskItem,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
