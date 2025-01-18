import 'package:flutter/material.dart';
import 'remark_page.dart';
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
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Remark'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RemarkPage(taskItem: taskItem)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Show Remark'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShowRemarkPage(taskItem: taskItem)),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
