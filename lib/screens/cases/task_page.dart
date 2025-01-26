import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/screens/cases/reassign_task_page.dart';
import 'package:intern_side/services/shared_pref.dart';

import '../../models/intern.dart';
import '../../models/task_item_list.dart';
import 'add_remark_page.dart';
import 'show_remark_page.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  TaskPageState createState() => TaskPageState();
}

class TaskPageState extends State<TaskPage> {
  List<TaskItem> taskList = [];
  bool isLoading = true;
  String errorMessage = '';
  Intern? _userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      _userData = await SharedPrefService.getUser();
      if (_userData == null || _userData!.id.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Intern data not found.';
        });
      } else {
        fetchTasks();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching user data: $e';
      });
    }
  }

  Future<void> fetchTasks() async {
    const String url =
        'https://pragmanxt.com/case_sync/services/intern/v1/index.php/intern_task_list';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['intern_id'] = _userData!.id;

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final parsedResponse = jsonDecode(responseBody);
        if (parsedResponse['success'] == true &&
            parsedResponse['data'] != null) {
          setState(() {
            taskList = (parsedResponse['data'] as List)
                .map((task) => TaskItem.fromJson(task))
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = parsedResponse['message'] ?? 'No tasks available.';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to fetch tasks.';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching tasks: $e';
      });
    }
  }

  void _navigateToReAssignTask(TaskItem taskItem) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReAssignTaskPage(
          task_id: taskItem.task_id,
          intern_id: _userData!.id,
        ),
      ),
    );

    if (result == true) {
      fetchTasks(); // Refresh the task list
    }
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
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Show Remark'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShowRemarkPage(
                      taskItem: taskItem,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_returned),
              title: const Text('Reassign Task'),
              enabled: !isRealloted,
              onTap: isRealloted
                  ? null
                  : () {
                      Navigator.pop(context);
                      _navigateToReAssignTask(taskItem);
                    },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back_arrow.svg',
            width: 32,
            height: 32,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Tasks',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF3F3F3),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : taskList.isNotEmpty
              ? ListView.builder(
                  itemCount: taskList.length,
                  itemBuilder: (context, index) {
                    final taskItem =
                        taskList.reversed.toList()[index]; // Reverse the list
                    return GestureDetector(
                      onTap: () {
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
                                'Instruction: ${taskItem.instruction}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Case No: ${taskItem.caseNo}',
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
                                'Alloted Date: ${taskItem.allotedDate?.toLocal().toString().split(' ')[0]}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'End Date: ${taskItem.expectedEndDate?.toLocal().toString().split(' ')[0]}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Status: ${taskItem.status}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Current Stage: ${taskItem.stage}',
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
}
