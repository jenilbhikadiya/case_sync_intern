import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:intern_side/screens/Tasks/reassign_task_page.dart';
import 'package:intern_side/services/shared_pref.dart';
import 'package:intern_side/utils/constants.dart';
import '../../components/basicUIcomponent.dart';
import '../../components/task_card.dart';
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
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      _userData = await SharedPrefService.getUser();
      if (_userData == null || _userData!.id.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Intern data not found.';
        });
      } else {
        await fetchTasks();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error fetching user data: $e';
        });
      }
    }
  }

  Future<void> fetchTasks() async {
    if (_userData == null || _userData!.id.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Cannot fetch tasks without intern data.';
        });
      }
      return;
    }

    if (!isLoading && mounted) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    const String url = '$baseUrl/intern_task_list';
    print('Fetching tasks for intern ID: ${_userData!.id}');

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['intern_id'] = _userData!.id;

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print('Task list response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final parsedResponse = jsonDecode(responseBody);
        if (parsedResponse['success'] == true &&
            parsedResponse['data'] != null &&
            parsedResponse['data'] is List) {
          if (mounted) {
            setState(() {
              taskList = (parsedResponse['data'] as List)
                  .map((taskJson) {
                    try {
                      return TaskItem.fromJson(
                          taskJson as Map<String, dynamic>);
                    } catch (e) {
                      print("Error parsing task item: $taskJson, Error: $e");
                      return null;
                    }
                  })
                  .whereType<TaskItem>()
                  .toList();
              isLoading = false;
              errorMessage = taskList.isEmpty ? 'No tasks available.' : '';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              taskList = [];
              isLoading = false;

              errorMessage = parsedResponse['message'] as String? ??
                  'Failed to load tasks or no tasks available.';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            taskList = [];
            isLoading = false;
            errorMessage =
                'Failed to fetch tasks (Status Code: ${response.statusCode}).';
          });
        }
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      if (mounted) {
        setState(() {
          taskList = [];
          isLoading = false;
          errorMessage = 'An error occurred while fetching tasks: $e';
        });
      }
    }
  }

  void _navigateToReAssignTask(TaskItem taskItem) async {
    if (_userData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not available.')));
      }
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReAssignTaskPage(
          task_id: taskItem.task_id,
          intern_id: _userData!.id,
        ),
      ),
    );

    if (result == true && mounted) {
      fetchTasks();
    }
  }

  void _showDropdownMenu(BuildContext context, TaskItem taskItem) {
    if (_userData == null) {
      print("Error: _userData is null in _showDropdownMenu");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Cannot perform actions: User data missing.")),
        );
      }
      return;
    }

    bool canModifyTask = (taskItem.alloted_to_id == _userData!.id) &&
        (taskItem.status.toLowerCase() != 'completed');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Wrap(
          children: [
            AnimatedListTile(
              leading: Icon(Icons.edit_note_outlined,
                  color: canModifyTask
                      ? Theme.of(context).iconTheme.color
                      : Colors.grey),
              title: Text('Add Remark',
                  style: TextStyle(
                      color: canModifyTask ? Colors.black : Colors.grey)),
              enabled: canModifyTask,
              onTap: !canModifyTask
                  ? null
                  : () async {
                      Navigator.pop(bottomSheetContext);
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
                      if (result == true && mounted) {
                        fetchTasks();
                      }
                    },
            ),
            AnimatedListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Show Remark'),
              enabled: true,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShowRemarkPage(taskItem: taskItem),
                  ),
                );
              },
            ),
            AnimatedListTile(
              leading: Icon(Icons.assignment_return_outlined,
                  color: canModifyTask
                      ? Theme.of(context).iconTheme.color
                      : Colors.grey),
              title: Text('Reassign Task',
                  style: TextStyle(
                      color: canModifyTask ? Colors.black : Colors.grey)),
              enabled: canModifyTask,
              onTap: !canModifyTask
                  ? null
                  : () {
                      Navigator.pop(bottomSheetContext);
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
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      itemBuilder: (context, index) {
                        final taskItem = taskList[index];

                        return TaskCard(
                          key: ValueKey(taskItem.task_id),
                          taskItem: taskItem,
                          onTap: () => _showDropdownMenu(context, taskItem),
                        );
                      },
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          errorMessage.isNotEmpty
                              ? errorMessage
                              : 'No tasks assigned.',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
            ),
    );
  }
}

class AnimatedListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final bool enabled;
  final VoidCallback? onTap;

  const AnimatedListTile({
    Key? key,
    required this.leading,
    required this.title,
    this.enabled = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? null : Theme.of(context).disabledColor;
    final effectiveTextStyle =
        enabled ? null : TextStyle(color: effectiveColor);

    return ListTile(
      leading: IconTheme.merge(
        data: IconThemeData(color: effectiveColor),
        child: leading,
      ),
      title: DefaultTextStyle.merge(
        style: effectiveTextStyle,
        child: title,
      ),
      enabled: enabled,
      onTap: onTap,
    );
  }
}
