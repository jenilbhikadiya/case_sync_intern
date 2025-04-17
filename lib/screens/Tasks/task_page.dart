import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

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
        if (parsedResponse['success'] == true &&
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
          throw Exception(parsedResponse['message'] ?? 'Failed to load tasks.');
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}');
      }
    } catch (e) {
      print('[FetchTasks] Error fetching: $e');

      if (mounted) {
        setState(() {
          _allTasks = [];
          _isLoadingTasks = false;
          _errorTasks = '$e';
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
            "[$logPrefix] Error parsing task item: Invalid data type in list - $taskJson");
        return null;
      }
    } catch (e, stacktrace) {
      print(
          "[$logPrefix] Error parsing task item: $taskJson \nError: $e\nStackTrace: $stacktrace");

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

    if (highlightedIndex != -1) {
      final taskToHighlight = _allTasks[highlightedIndex];

      final bool isInMyTasks = taskToHighlight.alloted_to_id == _userData!.id;
      final int targetTabIndex = isInMyTasks ? 0 : 1;
      final ScrollController targetController =
          isInMyTasks ? _myTasksScrollController : _createdByMeScrollController;

      List<TaskItem> filteredList;
      if (isInMyTasks) {
        filteredList = _allTasks
            .where((task) => task.alloted_to_id == _userData!.id)
            .toList();
      } else {
        filteredList = _allTasks
            .where((task) => task.alloted_to_id != _userData!.id)
            .toList();
      }

      final int indexInFilteredList = filteredList
          .indexWhere((task) => task.task_id == widget.highlightedTaskId);

      if (indexInFilteredList != -1) {
        if (mounted && _tabController!.index != targetTabIndex) {
          _tabController!.animateTo(targetTabIndex);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted && targetController.hasClients) {
              _scrollToIndex(indexInFilteredList, targetController);
            }
          });
        });
      }
    }
  }

  void _scrollToIndex(int index, ScrollController controller) {
    if (controller.hasClients) {
      const double itemEstimatedHeight = 280.0;
      final scrollOffset = index * itemEstimatedHeight;
      final maxScroll = controller.position.maxScrollExtent;
      final targetOffset = scrollOffset.clamp(0.0, maxScroll);

      controller.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
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
      print("Reassign returned true, refreshing all tasks...");
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
    bool canModifyAssignedTask = isAssignedToMe && isNotCompleted;

    print("\n--- [DEBUG] Task Action Check ---");
    print("Task ID: ${taskItem.task_id}, Status: ${taskItem.status}");
    print(
        "Assigned To: ${taskItem.alloted_to_id}, Current User: ${_userData!.id}");
    print("Is Assigned To Me: $isAssignedToMe");
    print("Is Not Completed: $isNotCompleted");
    print("Can Modify (As Assignee): $canModifyAssignedTask");
    print("--- End Check ---\n");

    if (!mounted) return;
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
                  color: canModifyAssignedTask
                      ? Theme.of(context).iconTheme.color
                      : Colors.grey),
              title: Text('Add Remark',
                  style: TextStyle(
                      color:
                          canModifyAssignedTask ? Colors.black : Colors.grey)),
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
            ),
            AnimatedListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Show Remarks'),
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
            ),
            AnimatedListTile(
              leading: Icon(Icons.assignment_return_outlined,
                  color: canModifyAssignedTask
                      ? Theme.of(context).iconTheme.color
                      : Colors.grey),
              title: Text('Reassign Task',
                  style: TextStyle(
                      color:
                          canModifyAssignedTask ? Colors.black : Colors.grey)),
              enabled: canModifyAssignedTask,
              onTap: !canModifyAssignedTask
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
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
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
                    ? 'No tasks found in this category.'
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
                    errorMessage.isNotEmpty ? errorMessage : 'No tasks found.',
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
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 12.0, bottom: 12.0),
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
                onTap: () => _showDropdownMenu(context, taskItem),
              ),
            );
          },
        ));
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
      splashColor: enabled ? Theme.of(context).splashColor : Colors.transparent,
      hoverColor: enabled ? Theme.of(context).hoverColor : Colors.transparent,
      focusColor: enabled ? Theme.of(context).focusColor : Colors.transparent,
    );
  }
}
