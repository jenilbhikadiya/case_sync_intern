import 'dart:convert'; // For jsonDecode if checking response body

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http; // Import HTTP package
import 'package:intern_side/models/notification_item.dart';
import 'package:intern_side/screens/Case_History/ProceedHistory.dart';
import 'package:intern_side/screens/Tasks/show_remark_page.dart';
import 'package:intern_side/screens/Tasks/task_page.dart'; // Make sure this path is correct
import 'package:intern_side/services/shared_pref.dart';
import 'package:intl/intl.dart';

// Adjust these imports based on your actual project structure
// import '../../models/task_item_list.dart'; // TaskItem is used only for ShowRemarkPage logic which seems commented out/replaced
// import '../Tasks/show_remark_page.dart'; // ShowRemarkPage seems unused now
import '../../models/task_item_list.dart';
import '../../utils/constants.dart'; // Assuming baseUrl is defined here

class NotificationCard extends StatefulWidget {
  final NotificationItem taskItem; // Variable holds a NotificationItem instance
  final bool isHighlighted;
  final Function(NotificationItem) onDismiss; // Callback when dismissed

  const NotificationCard({
    super.key,
    required this.taskItem,
    required this.onDismiss, // Required function for dismissal
    this.isHighlighted = false,
  });

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  // --- Function to call the read_notification API ---
  Future<void> _markNotificationAsRead(String notificationId) async {
    if (notificationId.isEmpty) {
      print(
          "Error: Cannot mark notification as read. Notification ID is empty.");
      return;
    }

    const String endpoint = '/read_notification';
    final String url = '$baseUrl$endpoint';
    print("Calling API to mark notification read: $url (ID: $notificationId)");

    try {
      final userId = (await SharedPrefService.getUser())!.id;
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['not_id'] = notificationId;
      request.fields['user_id'] = userId;

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        try {
          var decodedResponse = jsonDecode(responseBody);
          print("API Response: $decodedResponse");
          if (decodedResponse['success'] == true) {
            print('Successfully marked notification $notificationId as read.');
            widget.onDismiss(widget.taskItem);
          } else {
            print(
                'API indicated failure for notification $notificationId: ${decodedResponse['message'] ?? 'Unknown error'}');
          }
        } catch (e) {
          print("Could not decode API response body: $responseBody. Error: $e");
          print(
              'Successfully marked notification $notificationId as read (based on status code 200).');
        }
      } else {
        print(
            'API Error: Failed to mark notification $notificationId as read.');
        print('Status Code: ${response.statusCode}');
        print('Response Body: $responseBody');
      }
    } catch (e) {
      print(
          'Network Error calling read_notification for ID $notificationId: $e');
    }
  }

  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // This dummyTaskForRemark seems unnecessary if you navigate to TaskPage
    // which likely needs the actual taskId from the notification.
    // Keep it if ShowRemarkPage is still relevant somehow, otherwise remove.
    final dummyTaskForRemark = TaskItem(
      intern_id: '',
      caseNo: widget.taskItem.caseNo ?? 'N/A',
      instruction: widget.taskItem.instruction ?? 'N/A',
      allotedTo: '',
      alloted_to_id: '',
      allotedBy: widget.taskItem.allotedBy ?? '',
      added_by: '',
      allotedDate: null,
      expectedEndDate: null,
      status: '',
      task_id:
          widget.taskItem.typeId ?? '', // Use task_id from NotificationItem
      stage: '',
      stage_id: '',
      case_type: widget.taskItem.caseType ?? '', case_id: '',
    );

    // *** Print the taskItem (NotificationItem) object when the widget builds ***
    print(
        "Building NotificationCard for: ${widget.taskItem}"); // Optional: print during build

    return GestureDetector(
      onTap: () async {
        // *** ADDED PRINT STATEMENT HERE ***
        print("--- NotificationCard Tapped ---");
        // Using toString() implicitly. Add .toJson() if you have it for better formatting.
        print("NotificationItem Data: ${widget.taskItem}");
        print("-----------------------------");

        // Check if there's a valid task_id to navigate to the TaskPage
        // Ensure taskItem has a 'taskId' field
        final String? taskId = widget.taskItem.typeId;
        final String? type =
            widget.taskItem.type; // Assuming NotificationItem has taskId

        if (type == "task_assigned" || type == "task_reassigned") {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              // Navigate to TaskPage using the taskId from the NotificationItem
              builder: (context) => TaskPage(
                highlightedTaskId: taskId, // Pass the actual task ID
              ),
            ),
          );
          _markNotificationAsRead(widget.taskItem.id);
        } else if (type == "remark_added") {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              // Navigate to TaskPage using the taskId from the NotificationItem
              builder: (context) => ShowRemarkPage(
                highlightedTaskId: taskId,
                taskItem: dummyTaskForRemark, // Pass the actual task ID
              ),
            ),
          );
          _markNotificationAsRead(widget.taskItem.id);
        } else if (type == "case_proceed") {
          HapticFeedback.mediumImpact();
          await Navigator.push(
            context,
            MaterialPageRoute(
              // Navigate to TaskPage using the taskId from the NotificationItem
              builder: (context) => ViewProceedCaseHistoryScreen(
                highlightedTaskId: taskId,
                caseId: widget.taskItem.typeId,
                caseNo: widget.taskItem.caseNo,
              ),
            ),
          );
          _markNotificationAsRead(widget.taskItem.id);
        } else {
          print(
              "No valid taskId found in notification (taskId: $taskId), cannot navigate to TaskPage.");
          // Optionally show a snackbar message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "No associated task details found for this notification."),
                duration: Duration(seconds: 2)),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        color: widget.isHighlighted ? Colors.blueGrey[50] : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Dismissible(
          // *** IMPORTANT: Use the correct notification ID here ***
          key: Key(widget
              .taskItem.id), // Use the unique NOTIFICATION ID (taskItem.id)
          direction: DismissDirection.endToStart,
          background: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
              ),
              alignment: Alignment.centerRight,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Mark Read",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.mark_chat_read_rounded,
                      color: Colors.white, size: 24),
                ],
              )),
          onDismissed: (direction) {
            HapticFeedback.lightImpact();
            _markNotificationAsRead(widget.taskItem.id); // Mark as read via API
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.taskItem.caseNo != null &&
                    widget.taskItem.caseNo!.isNotEmpty) ...[
                  Text(
                    'Case No: ${widget.taskItem.caseNo}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color:
                          widget.isHighlighted ? Colors.black : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  widget.taskItem.instruction,
                  style: TextStyle(
                      fontSize: 15,
                      color: widget.isHighlighted ? Colors.black : Colors.black,
                      fontWeight: FontWeight.w500),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.taskItem.allotedBy != null &&
                        widget.taskItem.allotedBy!.isNotEmpty)
                      Flexible(
                        child: Text(
                          'By: ${widget.taskItem.allotedBy}',
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.isHighlighted
                                ? Colors.grey.shade800
                                : Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (widget.taskItem.date != null)
                      Text(
                        DateFormat('dd MMM, h:mm a')
                            .format(widget.taskItem.date!),
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.isHighlighted
                              ? Colors.grey.shade800
                              : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
