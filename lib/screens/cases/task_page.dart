import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'remark_page.dart';
import 'show_remark_page.dart';
import 'task_item.dart';

class TaskPage extends StatefulWidget {
  final String internId;

  const TaskPage({super.key, required this.internId});

  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  List<TaskItem> taskList = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    if (widget.internId.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'Invalid Intern ID';
      });
      return;
    }

    const String url =
        'https://pragmanxt.com/case_sync/services/intern/v1/index.php/intern_task_list';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['intern_id'] = widget.internId;

      var response = await request.send();
      if (response.statusCode == 200) {
        // Existing logic
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to fetch tasks. Server error.';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'An error occurred while fetching tasks: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Task Page',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: const Color(0xFFF3F3F3),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : taskList.isNotEmpty
              ? ListView.builder(
                  itemCount: taskList.length,
                  itemBuilder: (context, index) {
                    final taskItem = taskList[index];
                    return GestureDetector(
                      onLongPress: () {
                        _showDropdownMenu(context, taskItem);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 10.0),
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(
                              color: Colors.black, style: BorderStyle.solid),
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
                                    color: Colors.black),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Instruction: ${taskItem.instruction}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Alloted By: ${taskItem.allotedBy}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Alloted Date: ${taskItem.allotedDate.toLocal()}'
                                    .split(' ')[0],
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'End Date: ${taskItem.endDate.toLocal()}'
                                    .split(' ')[0],
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text(
                    errorMessage.isNotEmpty
                        ? errorMessage
                        : 'No tasks available.',
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
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
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RemarkPage(taskItem: taskItem)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Show Remark'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ShowRemarkPage(taskItem: taskItem)),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
