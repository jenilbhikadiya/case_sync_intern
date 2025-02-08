import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intern_side/models/notification_item.dart';
import 'package:intl/intl.dart';

import '../../models/task_item_list.dart';
import '../Tasks/show_remark_page.dart';

class NotificationCard extends StatelessWidget {
  final NotificationItem taskItem;
  final bool isHighlighted;
  final bool isTask;
  final Function(NotificationItem) onDismiss; // Callback when dismissed

  const NotificationCard({
    super.key,
    required this.taskItem,
    required this.onDismiss, // Required function for dismissal
    this.isHighlighted = false,
    this.isTask = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShowRemarkPage(
                taskItem: TaskItem(
                    intern_id: '',
                    caseNo: '',
                    instruction: '',
                    allotedTo: '',
                    allotedBy: '',
                    status: '',
                    task_id: taskItem.task_id,
                    stage: '',
                    case_id: '',
                    stage_id: '')),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        color: isHighlighted ? Colors.black : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, style: BorderStyle.solid),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Dismissible(
            key: Key(taskItem.task_id.toString()), // Unique key for each item
            direction: DismissDirection.endToStart, // Swipe left to dismiss
            background: Container(
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20)),
              alignment: Alignment.centerRight,
              child: const Icon(
                Icons.mark_chat_read_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            onDismissed: (direction) {
              HapticFeedback.lightImpact();
              onDismiss(taskItem); // Notify parent to remove item
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Case No: ${taskItem.caseNo}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: isHighlighted ? Colors.white : Colors.black,
                    ),
                  ),
                  Divider(
                    color: isHighlighted ? Colors.white : Colors.black,
                  ),
                  Text(
                    'Alloted By: ${taskItem.allotedBy}',
                    style: TextStyle(
                      fontSize: 15,
                      color: isHighlighted ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    'Date and Time: ${DateFormat('EEE, dd-MM-yyyy, h:mm a').format(taskItem.date!)}',
                    style: TextStyle(
                      fontSize: 15,
                      color: isHighlighted ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    taskItem.instruction,
                    style: TextStyle(
                      fontSize: 15,
                      color: isHighlighted ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
