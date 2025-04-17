import 'dart:convert'; // For jsonDecode if checking response body

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http; // Import HTTP package
import 'package:intern_side/models/notification_item.dart';
import 'package:intl/intl.dart';

// Adjust these imports based on your actual project structure
import '../../models/task_item_list.dart'; // Assuming TaskItem model is correctly defined
import '../Tasks/show_remark_page.dart'; // Assuming ShowRemarkPage exists
import '../../utils/constants.dart'; // Assuming baseUrl is defined here

class NotificationCard extends StatelessWidget {
  final NotificationItem
      taskItem; // Rename variable for clarity if it's just NotificationItem
  final bool isHighlighted;
  // final bool isTask; // isTask seems unused, can be removed if not needed
  final Function(NotificationItem) onDismiss; // Callback when dismissed

  const NotificationCard({
    super.key,
    required this.taskItem,
    required this.onDismiss, // Required function for dismissal
    this.isHighlighted = false,
    // this.isTask = false, // Removed if unused
  });

  // --- Function to call the read_notification API ---
  Future<void> _markNotificationAsRead(String notificationId) async {
    // Ensure notificationId is not empty
    if (notificationId.isEmpty) {
      print(
          "Error: Cannot mark notification as read. Notification ID is empty.");
      return;
    }

    const String endpoint = '/read_notification'; // API endpoint path
    final String url = '$baseUrl$endpoint';
    print("Calling API to mark notification read: $url (ID: $notificationId)");

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add the required field
      request.fields['not_id'] = notificationId;

      // Add specific headers if absolutely necessary (http package handles Content-Type for multipart)
      // request.headers.addAll({
      //   'User-Agent': 'Apidog/1.0.0 (https://apidog.com)', // Example if needed
      //   'Accept': '*/*',
      // });

      var response = await request.send();
      var responseBody =
          await response.stream.bytesToString(); // Read response body

      if (response.statusCode == 200) {
        // Optionally check response body for success message
        try {
          var decodedResponse = jsonDecode(responseBody);
          print("API Response: $decodedResponse");
          if (decodedResponse['success'] == true) {
            print('Successfully marked notification $notificationId as read.');
          } else {
            print(
                'API indicated failure for notification $notificationId: ${decodedResponse['message'] ?? 'Unknown error'}');
          }
        } catch (e) {
          print("Could not decode API response body: $responseBody. Error: $e");
          // Assume success based on status code if body parsing fails but status is 200
          print(
              'Successfully marked notification $notificationId as read (based on status code 200).');
        }
      } else {
        // Handle API error (non-200 status code)
        print(
            'API Error: Failed to mark notification $notificationId as read.');
        print('Status Code: ${response.statusCode}');
        print('Response Body: $responseBody');
        // Optionally show an error message to the user, though the item is already dismissed visually
      }
    } catch (e) {
      // Handle network errors or other exceptions during the API call
      print(
          'Network Error calling read_notification for ID $notificationId: $e');
      // Optionally show an error message
    }
  }
  // ---------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // --- Prepare data needed for the TaskItem constructor for ShowRemarkPage ---
    // It's unusual to create a dummy TaskItem here. Ideally, ShowRemarkPage
    // should be adaptable or you should navigate elsewhere if it's not a task remark.
    // This assumes ShowRemarkPage primarily needs the task_id.
    final dummyTaskForRemark = TaskItem(
      intern_id: '', // Provide defaults or fetch real data if needed/possible
      caseNo: taskItem.caseNo ??
          'N/A', // Use data from NotificationItem if available
      instruction:
          taskItem.instruction ?? 'N/A', // Use data from NotificationItem
      allotedTo: '',
      alloted_to_id: '',
      allotedBy: taskItem.allotedBy ?? '', // Use data from NotificationItem
      added_by: '',
      allotedDate: null,
      expectedEndDate: null,
      status: '',
      task_id: taskItem.taskId ?? '', // Use task_id from NotificationItem
      stage: '',
      case_id: taskItem.taskId ?? '', // Assuming NotificationItem has caseId
      stage_id: '',
      case_type:
          taskItem.caseType ?? '', // Assuming NotificationItem has caseType
    );
    // -----------------------------------------------------------------------

    return GestureDetector(
      onTap: () {
        // Check if there's a valid task_id to navigate to remarks
        if (dummyTaskForRemark.task_id.isNotEmpty) {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              // Navigate to ShowRemarkPage using the prepared (potentially dummy) TaskItem
              builder: (context) =>
                  ShowRemarkPage(taskItem: dummyTaskForRemark),
            ),
          );
        } else {
          print("No valid task_id found in notification, cannot show remarks.");
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
        margin: const EdgeInsets.symmetric(
            vertical: 6.0, horizontal: 4.0), // Adjusted margin
        color: isHighlighted
            ? Colors.blueGrey[50]
            : Colors.white, // Subtle highlight
        elevation: 2, // Reduced elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Slightly less rounded
          // Optional: remove border or make it lighter
          // side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        clipBehavior:
            Clip.antiAlias, // Ensures Dismissible background clips correctly
        child: Dismissible(
          // *** IMPORTANT: Use the correct notification ID here ***
          key: Key(taskItem.id.toString()), // Use the unique NOTIFICATION ID
          direction: DismissDirection.endToStart, // Swipe left to dismiss
          background: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.green.shade600, // Changed color for "Mark Read"
                // borderRadius applied by ClipRRect on Card
              ),
              alignment: Alignment.centerRight,
              child: const Row(
                // Added text for clarity
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
            // 1. Immediately notify the parent to remove the item from the UI
            onDismiss(taskItem);

            // 2. Call the API in the background to mark as read
            // Use the correct notification ID from taskItem
            _markNotificationAsRead(
                taskItem.id); // Assuming taskItem.id holds the 'not_id'
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0), // Adjusted padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Case Number if available
                if (taskItem.caseNo != null && taskItem.caseNo!.isNotEmpty) ...[
                  Text(
                    'Case No: ${taskItem.caseNo}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Changed weight
                      fontSize: 16, // Adjusted size
                      color: isHighlighted ? Colors.black : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4), // Smaller divider spacing
                  // Divider(color: isHighlighted ? Colors.grey.shade400 : Colors.grey.shade300, height: 8),
                  // const SizedBox(height: 4),
                ],

                // Display Notification Title/Instruction
                Text(
                  taskItem.instruction, // Main content of the notification
                  style: TextStyle(
                      fontSize: 15,
                      color: isHighlighted ? Colors.black : Colors.black,
                      fontWeight: FontWeight.w500 // Make text slightly bolder
                      ),
                  maxLines: 3, // Limit lines
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Row for metadata (Alloted By and Date)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Display Alloted By if available
                    if (taskItem.allotedBy != null &&
                        taskItem.allotedBy!.isNotEmpty)
                      Flexible(
                        // Use flexible to prevent overflow
                        child: Text(
                          'By: ${taskItem.allotedBy}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isHighlighted
                                ? Colors.grey.shade800
                                : Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Display Date and Time (ensure date is not null)
                    if (taskItem.date != null)
                      Text(
                        // Use a shorter format maybe? e.g., 'dd-MM-yy, h:mm a'
                        DateFormat('dd MMM, h:mm a').format(taskItem.date!),
                        style: TextStyle(
                          fontSize: 13,
                          color: isHighlighted
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
