import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import 'package:intern_side/screens/Tasks/reassign_task_page.dart';
import 'package:intern_side/services/shared_pref.dart';
import 'package:intern_side/utils/constants.dart';
import 'package:intern_side/components/basicUIcomponent.dart';
import 'package:intern_side/components/task_card.dart';
import 'package:intern_side/models/intern.dart';
import 'package:intern_side/models/task_item_list.dart';
import 'package:intern_side/screens/Tasks/add_remark_page.dart';
import 'package:intern_side/screens/Tasks/show_remark_page.dart';

class TaskPage extends StatefulWidget {
  final String? highlightedTaskId;
  final int initialTabIndex;

  const TaskPage({
    super.key,
    this.highlightedTaskId,
    this.initialTabIndex = 0,
  });

  @override
  TaskPageState createState() => TaskPageState();
}

class TaskPageState extends State<TaskPage>
    with SingleTickerProviderStateMixin {
  List<TaskItem> _allTasks = [];
  bool _isLoadingTasks = true;
  String _errorTasks = '';
  Intern? _userData;
  TabController? _tabController;

  final ScrollController _myTasksScrollController = ScrollController();
  final ScrollController _createdByMeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _fetchUserDataAndTasks();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _myTasksScrollController.dispose();
    _createdByMeScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDataAndTasks() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTasks = true;
      _errorTasks = '';
    });
    try {
      _userData = await SharedPrefService.getUser();
      if (_userData == null || _userData!.id.isEmpty) {
        throw Exception('User data not found. Cannot load tasks.');
      }

      await _fetchTasks();
    } catch (e) {
      print("Error during initial data fetch: $e");
      if (mounted) {
        setState(() {
          _isLoadingTasks = false;
          _errorTasks = 'Error loading data: $e';
          _allTasks = [];
        });
      }
    }
  }

  Future<void> _fetchTasks() async {
    if (_userData == null || _userData!.id.isEmpty) {
      if (mounted) {
        setState(() {
          _errorTasks = 'User data not available. Cannot fetch tasks.';
          _isLoadingTasks = false;
          _allTasks = [];
        });
      }
      return;
    }

    if (!_isLoadingTasks && mounted) {
      setState(() => _isLoadingTasks = true);
    }
    if (mounted) {
      setState(() => _errorTasks = '');
    }

    final String url = '$baseUrl/intern_task_list';
    print(
        '[FetchTasks] Fetching all tasks for intern ID: ${_userData!.id} from $url');

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['intern_id'] = _userData!.id;

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('[FetchTasks] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final parsedResponse = jsonDecode(responseBody);

        if (parsedResponse is Map &&
            parsedResponse['success'] == true &&
            parsedResponse['data'] is List) {
          final List<TaskItem> fetchedList = (parsedResponse['data'] as List)
              .map((taskJson) => _parseTaskItem(taskJson, 'FetchTasks'))
              .whereType<TaskItem>()
              .toList();

          if (mounted) {
            setState(() {
              _allTasks = fetchedList;
              _isLoadingTasks = false;
            });

            _attemptScrollToHighlight();
          }
        } else {
          throw Exception(parsedResponse is Map
              ? parsedResponse['message'] ??
                  'Failed to load tasks: Invalid response structure.'
              : 'Failed to load tasks: Unexpected response format.');
        }
      } else {
        throw Exception(
            'Failed to load tasks. Server responded with status ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      print('[FetchTasks] Error fetching or parsing tasks: $e');
      print('[FetchTasks] Stacktrace: $stacktrace');
      if (mounted) {
        setState(() {
          _allTasks = [];
          _isLoadingTasks = false;
          _errorTasks =
              'Failed to load tasks. Please check your connection and try again.';
        });
      }
    }
  }

  TaskItem? _parseTaskItem(dynamic taskJson, String logPrefix) {
    try {
      if (taskJson is Map<String, dynamic>) {
        return TaskItem.fromJson(taskJson);
      } else {
        print(
            "[$logPrefix] Error parsing task item: Expected a Map but got ${taskJson.runtimeType}");
        return null;
      }
    } catch (e, stacktrace) {
      print(
          "[$logPrefix] Error parsing task item JSON: $taskJson \nError: $e\nStackTrace: $stacktrace");
      return null;
    }
  }

  void _attemptScrollToHighlight() {
    if (widget.highlightedTaskId == null ||
        widget.highlightedTaskId!.isEmpty ||
        _allTasks.isEmpty ||
        _tabController == null ||
        _userData == null) {
      return;
    }

    final highlightedIndex = _allTasks
        .indexWhere((task) => task.task_id == widget.highlightedTaskId);
    if (highlightedIndex == -1) {
      print(
          "[Scroll] Highlighted task ID ${widget.highlightedTaskId} not found in all tasks.");
      return;
    }

    final taskToHighlight = _allTasks[highlightedIndex];

    final bool isInMyTasks = taskToHighlight.alloted_to_id == _userData!.id;
    final int targetTabIndex = isInMyTasks ? 0 : 1;
    final ScrollController targetController =
        isInMyTasks ? _myTasksScrollController : _createdByMeScrollController;

    final List<TaskItem> filteredList = isInMyTasks
        ? _allTasks
            .where((task) => task.alloted_to_id == _userData!.id)
            .toList()
        : _allTasks
            .where((task) => task.alloted_to_id != _userData!.id)
            .toList();

    final int indexInFilteredList = filteredList
        .indexWhere((task) => task.task_id == widget.highlightedTaskId);
    if (indexInFilteredList == -1) {
      print(
          "[Scroll] Highlighted task ID ${widget.highlightedTaskId} not found in filtered list for tab $targetTabIndex.");
      return;
    }

    if (mounted && _tabController!.index != targetTabIndex) {
      _tabController!.animateTo(targetTabIndex);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && targetController.hasClients) {
          _scrollToIndex(indexInFilteredList, targetController);
        } else if (mounted) {
          print(
              "[Scroll] Target scroll controller doesn't have clients attached. Cannot scroll.");
        }
      });
    });
  }

  void _scrollToIndex(int index, ScrollController controller) {
    if (!controller.hasClients) {
      print("[Scroll] Cannot scroll, controller has no clients.");
      return;
    }

    const double itemEstimatedHeight = 280.0;

    final double scrollOffset = index * itemEstimatedHeight;
    final double maxScroll = controller.position.maxScrollExtent;
    final double targetOffset = scrollOffset.clamp(0.0, maxScroll);

    print(
        "[Scroll] Scrolling controller to index $index, target offset $targetOffset (max: $maxScroll)");

    controller.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToReAssignTask(TaskItem taskItem) async {
    if (_userData == null) {
      _showErrorSnackbar('User data not available.');
      return;
    }
    if (taskItem.task_id.isEmpty) {
      _showErrorSnackbar('Task ID is missing, cannot reassign.');
      return;
    }

    if (!mounted) return;
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
      print("[Reassign] Task reassigned/updated, refreshing task list.");
      await _fetchTasks();
    }
  }

  void _showDropdownMenu(BuildContext context, TaskItem taskItem) {
    if (_userData == null) {
      print("[DEBUG] Error in _showDropdownMenu: _userData is null.");
      _showErrorSnackbar("Cannot perform actions: User data missing.");
      return;
    }

    bool isAssignedToMe = taskItem.alloted_to_id == _userData!.id;
    bool isNotCompleted = taskItem.status.toLowerCase() != 'completed';
    bool isAllotted = taskItem.status.toLowerCase() == 'allotted';

    bool canModifyAssignedTask =
        (isAssignedToMe && isNotCompleted) || isAllotted;

    print("\n--- [DEBUG] Task Action Check ---");
    print(
        "Task ID: ${taskItem.task_id}, Status: ${taskItem.status}, Title: ${taskItem.caseNo ?? 'N/A'}");
    print(
        "Assigned To: ${taskItem.alloted_to_id ?? 'None'}, Current User: ${_userData!.id}");
    print("Is Assigned To Me: $isAssignedToMe");
    print("Is Not Completed: $isNotCompleted");
    print("Is Allotted: $isAllotted");
    print("Can Modify: $canModifyAssignedTask");
    print("--- End Check ---\n");

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 10,
              left: 16,
              right: 16,
              top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // 2. Title Area (Modified)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 12.0, left: 8.0, right: 8.0),
                child: Text(
                  // Construct the string with the desired format
                  'Case Number : ${taskItem.caseNo ?? 'N/A'}', // Added prefix and null check
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge // Use titleLarge for emphasis
                      ?.copyWith(
                          fontWeight: FontWeight.w600), // Keep bold weight
                  overflow:
                      TextOverflow.ellipsis, // Keep ellipsis for long numbers
                ),
              ),
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: Icon(
                  Icons.edit_note_outlined,
                  color: canModifyAssignedTask
                      ? Colors.black
                      : Theme.of(context).disabledColor,
                ),
                title: Text(
                  'Add Remark',
                  style: TextStyle(
                    color: canModifyAssignedTask
                        ? Colors.black87
                        : Theme.of(context).disabledColor,
                  ),
                ),
                enabled: canModifyAssignedTask,
                onTap: !canModifyAssignedTask
                    ? null
                    : () async {
                        Navigator.pop(bottomSheetContext);
                        if (!mounted) return;

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
                          await _fetchTasks();
                        }
                      },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              ),
              ListTile(
                leading: Icon(Icons.chat_bubble_outline, color: Colors.black),
                title: const Text('Show Remarks',
                    style: TextStyle(color: Colors.black87)),
                enabled: true,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShowRemarkPage(taskItem: taskItem),
                    ),
                  );
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              ),
              ListTile(
                leading: Icon(
                  Icons.assignment_return_outlined,
                  color: canModifyAssignedTask
                      ? Colors.black
                      : Theme.of(context).disabledColor,
                ),
                title: Text(
                  'Reassign Task',
                  style: TextStyle(
                    color: canModifyAssignedTask
                        ? Colors.black87
                        : Theme.of(context).disabledColor,
                  ),
                ),
                enabled: canModifyAssignedTask,
                onTap: !canModifyAssignedTask
                    ? null
                    : () {
                        Navigator.pop(bottomSheetContext);
                        _navigateToReAssignTask(taskItem);
                      },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    if (mounted && ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      print(
          "[Snackbar Error] Could not show snackbar: $message (mounted: $mounted)");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness platformBrightness =
        MediaQuery.platformBrightnessOf(context);
    final Color refreshIndicatorColor =
        AppTheme.getRefreshIndicatorColor(platformBrightness);
    final Color refreshIndicatorBgColor =
        AppTheme.getRefreshIndicatorBackgroundColor();

    final List<TaskItem> tasksForMe = _userData == null
        ? []
        : _allTasks
            .where((task) => task.alloted_to_id == _userData!.id)
            .toList();

    final List<TaskItem> tasksCreatedByMe = _userData == null
        ? []
        : _allTasks
            .where((task) => task.alloted_to_id != _userData!.id)
            .toList();

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back_arrow.svg',
            width: 24,
            height: 24,
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.black,
          indicatorWeight: 3.0,
          tabs: [
            Tab(text: 'Tasks for Me (${tasksForMe.length})'),
            Tab(text: 'Created by Me (${tasksCreatedByMe.length})'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF3F3F3),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskListWidget(
            taskList: tasksForMe,
            isLoading: _isLoadingTasks,
            errorMessage: _errorTasks.isNotEmpty
                ? _errorTasks
                : (tasksForMe.isEmpty && !_isLoadingTasks
                    ? 'No tasks assigned to you.'
                    : ''),
            scrollController: _myTasksScrollController,
            onRefresh: _fetchTasks,
            refreshIndicatorColor: refreshIndicatorColor,
            refreshIndicatorBgColor: refreshIndicatorBgColor,
          ),
          _buildTaskListWidget(
            taskList: tasksCreatedByMe,
            isLoading: _isLoadingTasks,
            errorMessage: _errorTasks.isNotEmpty
                ? _errorTasks
                : (tasksCreatedByMe.isEmpty && !_isLoadingTasks
                    ? 'You have not created tasks assigned to others.'
                    : ''),
            scrollController: _createdByMeScrollController,
            onRefresh: _fetchTasks,
            refreshIndicatorColor: refreshIndicatorColor,
            refreshIndicatorBgColor: refreshIndicatorBgColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListWidget({
    required List<TaskItem> taskList,
    required bool isLoading,
    required String errorMessage,
    required ScrollController scrollController,
    required Future<void> Function() onRefresh,
    required Color refreshIndicatorColor,
    required Color refreshIndicatorBgColor,
  }) {
    if (isLoading && taskList.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.black));
    }

    if (!isLoading && taskList.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          onRefresh: onRefresh,
          color: refreshIndicatorColor,
          backgroundColor: refreshIndicatorBgColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    errorMessage.isNotEmpty
                        ? errorMessage
                        : 'No tasks found in this category.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: refreshIndicatorColor,
      backgroundColor: refreshIndicatorBgColor,
      child: ListView.builder(
        controller: scrollController,
        itemCount: taskList.length,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        itemBuilder: (context, index) {
          final taskItem = taskList[index];

          final bool isHighlighted =
              taskItem.task_id == widget.highlightedTaskId;

          final bool showNewTaskTag = isHighlighted;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TaskCard(
              key: ValueKey(taskItem.task_id),
              taskItem: taskItem,
              isHighlighted: isHighlighted,
              showNewTaskTag: showNewTaskTag,
              onTap: () => {},
              onLongPress: _showDropdownMenu,
            ),
          );
        },
      ),
    );
  }
}
