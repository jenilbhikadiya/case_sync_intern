import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/screens/Tasks/reassign_task_page.dart';
import 'package:intern_side/services/shared_pref.dart';
import 'package:intern_side/utils/constants.dart';
import '../../components/basicUIcomponent.dart';
import '../../models/intern.dart';
import '../../models/task_item_list.dart';
import '../Tasks/add_remark_page.dart';
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
    const String url = '$baseUrl/intern_task_list';

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
    bool isRealloted = (taskItem.status.toLowerCase() == 're_alloted' ||
        taskItem.status.toLowerCase() == 'completed');

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Add Remark'),
              enabled: !isRealloted,
              onTap: () async {
                Navigator.pop(context); // Close dropdown first
                final result = await Navigator.push(
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
                if (result == true) {
                  fetchTasks(); // Refresh the task list after returning
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Show Remark'),
              onTap: () {
                Navigator.pop(context); // Close dropdown first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShowRemarkPage(taskItem: taskItem),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_returned),
              title: const Text('Reassign Task'),
              enabled: !isRealloted,
              onTap: () {
                Navigator.pop(context); // Close dropdown first
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
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.black,
            ))
          : RefreshIndicator(
              onRefresh: fetchTasks,
              color: AppTheme.getRefreshIndicatorColor(
                  Theme.of(context).brightness),
              backgroundColor: AppTheme.getRefreshIndicatorBackgroundColor(),
              child: taskList.isNotEmpty
                  ? ListView.builder(
                      itemCount: taskList.length,
                      itemBuilder: (context, index) {
                        final taskItem = taskList.toList()[index];
                        return GestureDetector(
                          onTap: () {
                            _showDropdownMenu(context, taskItem);
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildField(
                                      'Instruction', taskItem.instruction),
                                  const SizedBox(height: 16),
                                  _buildField('Case No', taskItem.caseNo),
                                  const SizedBox(height: 16),
                                  _buildField('Alloted By', taskItem.allotedBy),
                                  const SizedBox(height: 16),
                                  _buildField(
                                      'Alloted Date',
                                      taskItem.allotedDate
                                              ?.toLocal()
                                              .toString()
                                              .split(' ')[0] ??
                                          'N/A'),
                                  const SizedBox(height: 16),
                                  _buildField(
                                      'End Date',
                                      taskItem.expectedEndDate
                                              ?.toLocal()
                                              .toString()
                                              .split(' ')[0] ??
                                          'N/A'),
                                  const SizedBox(height: 16),
                                  _buildStatusField('Status', taskItem.status),
                                  const SizedBox(height: 16),
                                  _buildField('Current Stage', taskItem.stage),
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
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
            ),
    );
  }
}

Widget _buildField(String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 2,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 16.0,
          ),
        ),
      ),
    ],
  );
}

Widget _buildStatusField(String label, String status) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 2,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: getStatusColor(status),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
