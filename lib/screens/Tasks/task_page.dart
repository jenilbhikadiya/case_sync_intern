import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart'; // Make sure flutter_svg is in pubspec.yaml
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Used if formatting dates in TaskPage/TaskCard

// Adjust these imports based on your project structure
import 'package:intern_side/screens/Tasks/reassign_task_page.dart';
import 'package:intern_side/services/shared_pref.dart';
import 'package:intern_side/utils/constants.dart';
import '../../components/basicUIcomponent.dart'; // Assuming AppTheme is here
import '../../components/task_card.dart'; // Import the modified TaskCard
import '../../models/intern.dart';
import '../../models/task_item_list.dart';
import '../Tasks/add_remark_page.dart';
// import '../add_task/add_task_screen.dart'; // Likely unused
import 'show_remark_page.dart';

class TaskPage extends StatefulWidget {
  final String? highlightedTaskId; // ID from notification to highlight

  const TaskPage({
    super.key,
    this.highlightedTaskId,
  });

  @override
  TaskPageState createState() => TaskPageState();
}

class TaskPageState extends State<TaskPage> {
  List<TaskItem> taskList = [];
  bool isLoading = true;
  String errorMessage = '';
  Intern? _userData;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Start data fetching process
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fetches user data from shared preferences
  Future<void> fetchUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      _userData = await SharedPrefService.getUser();
      if (_userData == null || _userData!.id.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = 'User data not found. Cannot load tasks.';
          });
        }
      } else {
        // If user data is found, fetch tasks
        await fetchTasks();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error fetching user data: $e';
        });
      }
      print("Error fetching user data: $e");
    }
  }

  // Fetches the list of tasks for the logged-in intern
  Future<void> fetchTasks() async {
    if (_userData == null || _userData!.id.isEmpty) {
      print("fetchTasks called but _userData is null or ID is empty.");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Cannot fetch tasks without user data.';
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

    final String url = '$baseUrl/intern_task_list';
    print('Fetching tasks from: $url for intern ID: ${_userData!.id}');

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['intern_id'] = _userData!.id;

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print('Task list response status: ${response.statusCode}');
      // print('Task list response body: $responseBody'); // Uncomment for detailed debugging

      if (response.statusCode == 200) {
        final parsedResponse = jsonDecode(responseBody);
        if (parsedResponse['success'] == true &&
            parsedResponse['data'] != null &&
            parsedResponse['data'] is List) {
          final newTaskList = (parsedResponse['data'] as List)
              .map((taskJson) {
                try {
                  return TaskItem.fromJson(taskJson as Map<String, dynamic>);
                } catch (e) {
                  print("Error parsing task item: $taskJson \nError: $e");
                  return null;
                }
              })
              .whereType<TaskItem>()
              .toList();

          if (mounted) {
            setState(() {
              taskList = newTaskList;
              isLoading = false;
              errorMessage = taskList.isEmpty ? 'No tasks available.' : '';
            });
            _attemptScrollToHighlight();
          }
        } else {
          if (mounted) {
            setState(() {
              taskList = [];
              isLoading = false;
              errorMessage = parsedResponse['message'] as String? ??
                  'Failed to load tasks (Invalid data format or no tasks).';
            });
          }
          print(
              "API Error (Success False or Data Null/Wrong Type): ${parsedResponse['message'] ?? 'Unknown API error'}");
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
        print("HTTP Error ${response.statusCode}: $responseBody");
      }
    } catch (e, stacktrace) {
      print('Error fetching tasks: $e\n$stacktrace');
      if (mounted) {
        setState(() {
          taskList = [];
          isLoading = false;
          errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  // Schedules scrolling attempt after frame build
  void _attemptScrollToHighlight() {
    if (widget.highlightedTaskId != null && taskList.isNotEmpty) {
      final highlightedIndex = taskList
          .indexWhere((task) => task.task_id == widget.highlightedTaskId);

      if (highlightedIndex != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToIndex(highlightedIndex);
          }
        });
      } else {
        print(
            "Highlighted task ID ${widget.highlightedTaskId} not found in the current list.");
      }
    }
  }

  // Helper function to scroll to a specific index in the list
  void _scrollToIndex(int index) {
    if (_scrollController.hasClients) {
      const double itemEstimatedHeight = 280.0; // ADJUST THIS VALUE!
      final scrollOffset = index * itemEstimatedHeight;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetOffset = scrollOffset.clamp(0.0, maxScroll);

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      print("Attempting to scroll to index $index (offset: $targetOffset)");
    } else {
      print("Scroll controller has no clients, cannot scroll.");
    }
  }

  // Navigates to the ReAssign Task page
  void _navigateToReAssignTask(TaskItem taskItem) async {
    if (_userData == null) {
      _showErrorSnackbar('User data not available.');
      return;
    }
    if (taskItem.task_id.isEmpty) {
      _showErrorSnackbar('Task ID is missing, cannot reassign.');
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

  // Shows the bottom sheet with task actions
  void _showDropdownMenu(BuildContext context, TaskItem taskItem) {
    if (_userData == null) {
      print("Error: _userData is null in _showDropdownMenu");
      _showErrorSnackbar("Cannot perform actions: User data missing.");
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
          children: <Widget>[
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
              title: const Text('Show Remarks'),
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

  // Helper to show snackbar messages
  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back_arrow.svg',
            width: 32,
            height: 32,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          tooltip: 'Back',
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
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              onRefresh: fetchTasks,
              color: AppTheme.getRefreshIndicatorColor(
                  Theme.of(context).brightness),
              backgroundColor: AppTheme.getRefreshIndicatorBackgroundColor(),
              child: _buildTaskList(), // Use helper method
            ),
    );
  }

  // ***** THIS IS THE METHOD WITH DEBUG PRINTS ADDED *****
  Widget _buildTaskList() {
    if (taskList.isNotEmpty) {
      print("--- Building Task List ---"); // Added print
      return ListView.builder(
        controller: _scrollController, // Attach scroll controller
        itemCount: taskList.length,
        padding: const EdgeInsets.symmetric(
            horizontal: 12.0, vertical: 8.0), // Adjust padding
        itemBuilder: (context, index) {
          final taskItem = taskList[index];
          final bool isHighlighted =
              taskItem.task_id == widget.highlightedTaskId;

          // --- **** DEBUGGING AREA **** ---
          print("Task Index: $index, ID: ${taskItem.task_id}");
          print(
              "  Status Value: '${taskItem.status}'"); // Print the exact status string
          // Add prints for other relevant fields if your condition uses them (like date)
          // print("  Allotted Date: ${taskItem.allottedDate}");

          // --- YOUR CONDITION TO SHOW THE "NEW" TAG ---
          // Make sure this condition matches your actual data!
          final bool shouldShowNewTag =
              taskItem.task_id == widget.highlightedTaskId;
          // -------------------------------------------

          print(
              "  Checking condition (status == 'pending'): $shouldShowNewTag"); // Print the result
          // --- **** END DEBUGGING AREA **** ---

          return TaskCard(
            key: ValueKey(taskItem.task_id), // Important for list updates
            taskItem: taskItem,
            isHighlighted: isHighlighted,
            showNewTaskTag: shouldShowNewTag, // Pass the calculated flag
            onTap: () => _showDropdownMenu(context, taskItem),
          );
        },
      );
    } else {
      // Display error message or "No tasks" message
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  errorMessage.isNotEmpty
                      ? errorMessage
                      : 'No tasks assigned yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
// ***** END OF METHOD WITH DEBUG PRINTS *****
}

// --- AnimatedListTile Widget (Keep as is) ---
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
    final Color effectiveColor = enabled
        ? Theme.of(context).listTileTheme.iconColor ??
            Theme.of(context).iconTheme.color ??
            Colors.black
        : Theme.of(context).disabledColor;
    final TextStyle effectiveTextStyle = enabled
        ? Theme.of(context).listTileTheme.titleTextStyle ??
            Theme.of(context).textTheme.titleMedium ??
            const TextStyle()
        : Theme.of(context)
                .listTileTheme
                .titleTextStyle
                ?.copyWith(color: Theme.of(context).disabledColor) ??
            Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Theme.of(context).disabledColor) ??
            TextStyle(color: Theme.of(context).disabledColor);

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
      splashColor: Theme.of(context).splashColor,
      hoverColor: Theme.of(context).hoverColor,
    );
  }
}
