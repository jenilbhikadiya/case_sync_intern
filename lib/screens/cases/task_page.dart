import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'remark_page.dart';  // Assuming this is where RemarkPage is imported
=======
<<<<<<< HEAD
import 'package:http/http.dart' as http;
import 'package:intern_side/screens/cases/reassign_task_page.dart';
import 'package:intern_side/services/shared_pref.dart';

import '../../models/intern.dart';
import '../../models/task_item_list.dart';
import 'add_remark_page.dart';
=======
import 'remark_page.dart';  // Assuming this is where RemarkPage is imported
>>>>>>> 277f9bee96bd777278ea9326a8c832e20c61ca95
>>>>>>> Stashed changes
import 'show_remark_page.dart';
import 'task_item.dart';

class TaskPage extends StatelessWidget {
  final List<TaskItem> taskList = [
    TaskItem(
      caseNo: "case-777",
      instruction: "work fast",
      allotedBy: "N/A",
      allotedDate: DateTime(2024, 11, 25),
      endDate: DateTime(2024, 11, 25),
    ),
    TaskItem(
      caseNo: "case-123",
      instruction: "complete soon",
      allotedBy: "Admin",
      allotedDate: DateTime(2024, 11, 20),
      endDate: DateTime(2024, 11, 30),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Task Page',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      backgroundColor: const Color(0xFFF3F3F3),
      body: ListView.builder(
        itemCount: taskList.length,
        itemBuilder: (context, index) {
          final taskItem = taskList[index];
          return GestureDetector(
            onLongPress: () {
              _showDropdownMenu(context, taskItem);
            },
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.black, style: BorderStyle.solid),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Case No: ${taskItem.caseNo}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Instruction: ${taskItem.instruction}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Alloted By: ${taskItem.allotedBy}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Alloted Date: ${taskItem.allotedDate.day.toString().padLeft(2, '0')}/'
                          '${taskItem.allotedDate.month.toString().padLeft(2, '0')}/'
                          '${taskItem.allotedDate.year}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'End Date: ${taskItem.endDate.day.toString().padLeft(2, '0')}/'
                          '${taskItem.endDate.month.toString().padLeft(2, '0')}/'
                          '${taskItem.endDate.year}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDropdownMenu(BuildContext context, TaskItem taskItem) {
    bool isRealloted = taskItem.status.toLowerCase() == 're_alloted';

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
<<<<<<< Updated upstream
=======
<<<<<<< HEAD
              title: const Text('Add Remark'),
              enabled: !isRealloted, // Disable if status is "re_alloted"
              onTap: isRealloted
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddRemarkPage(
                            taskItem: taskItem,
                            task_id: taskItem.task_id,
                            case_id: taskItem.case_id,
                            stage_id: taskItem.stage_id,
                          ),
                        ),
                      );
                    },
=======
>>>>>>> Stashed changes
              title: const Text('Remark'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RemarkPage(taskItem: taskItem)),
                );
              },
>>>>>>> 277f9bee96bd777278ea9326a8c832e20c61ca95
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Show Remark'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                Navigator.push(
                  context,
<<<<<<< Updated upstream
=======
<<<<<<< HEAD
                  MaterialPageRoute(
                    builder: (context) => ShowRemarkPage(
                        taskItem: taskItem), // Pass taskItem here
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_returned),
              title: const Text('Reassign Task'),
              enabled: !isRealloted, // Disable if status is "re_alloted"
              onTap: isRealloted
                  ? null
                  : () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReAssignTaskPage(
                            task_id: taskItem.task_id,
                            intern_id: _userData!.id,
                          ),
                        ),
                      );
                    },
=======
>>>>>>> Stashed changes
                  MaterialPageRoute(builder: (context) => ShowRemarkPage(taskItem: taskItem)),
                );
              },
>>>>>>> 277f9bee96bd777278ea9326a8c832e20c61ca95
            ),
          ],
        );
      },
    );
  }
}
