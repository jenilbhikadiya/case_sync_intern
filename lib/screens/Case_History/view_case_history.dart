import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/screens/Case_History/task_info_screen.dart';
import 'package:intern_side/screens/Tasks/show_remark_page.dart';

import '../../components/basicUIcomponent.dart';
import '../../components/list_app_bar.dart';
import '../../models/intern.dart';
import '../../models/task_item_list.dart';
import '../../services/shared_pref.dart';
import '../../utils/constants.dart';

class ViewCaseHistoryScreen extends StatefulWidget {
  final String caseId;
  final String caseNo;

  const ViewCaseHistoryScreen(
      {super.key, required this.caseId, required this.caseNo});

  @override
  State<ViewCaseHistoryScreen> createState() => _ViewCaseHistoryScreenState();
}

class _ViewCaseHistoryScreenState extends State<ViewCaseHistoryScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<TaskItem> _caseHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchInternTaskList();
  }

  Future<void> _fetchInternTaskList() async {
    try {
      Intern? internData = await SharedPrefService.getUser();
      if (internData == null || internData.id.isEmpty) {
        setState(() {
          _errorMessage = 'Intern data not found.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/intern_task_list'),
        body: {
          'case_id': widget.caseId,
          'intern_id': internData.id,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data['success'] == true && data['data'] != null) {
            _caseHistory = (data['data'] as List)
                .map((taskData) => TaskItem.fromJson(taskData))
                .toList();
          } else {
            _errorMessage = data['message'] ?? 'No data found.';
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load case history.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _showDropdownMenu(BuildContext context, TaskItem taskItem) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Task Info'),
              onTap: () {
                Navigator.pop(context); // Close dropdown first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskInfoScreen(
                      taskItem: taskItem,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Remark List'),
              onTap: () {
                Navigator.pop(context); // Close dropdown first
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
          ],
        );
      },
    );
  }

  void _showRemarksDialog(BuildContext context, TaskItem taskItem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remarks'),
          content: Text(
              'Remarks: ${taskItem.instruction}'), // Assuming instruction is used for remarks
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: ListAppBar(
        onSearchPressed: () {},
        title: 'View Case History',
      ),
      body: RefreshIndicator(
        onRefresh: _fetchInternTaskList,
        color: AppTheme.getRefreshIndicatorColor(Theme.of(context).brightness),
        backgroundColor: AppTheme.getRefreshIndicatorBackgroundColor(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.black))
                    : _errorMessage.isNotEmpty
                        ? Column(
                            children: [
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.4),
                              Center(child: Text(_errorMessage)),
                            ],
                          )
                        : Column(
                            children: _caseHistory.asMap().entries.map((entry) {
                              int index = entry.key + 1; // for serial number
                              TaskItem taskItem = entry.value;
                              return GestureDetector(
                                onTap: () {
                                  _showDropdownMenu(context, taskItem);
                                },
                                child: Center(
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: const BorderSide(
                                          color: Colors.black,
                                          style: BorderStyle.solid),
                                    ),
                                    child: Container(
                                      width: screenWidth * 0.9,
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Sr No: $index',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18)),
                                          const SizedBox(height: 0),
                                          Text('Case No: ${taskItem.caseNo}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18)),
                                          const SizedBox(height: 5),
                                          Text(
                                              'Instruction: ${taskItem.instruction}'),
                                          Text('Status: ${taskItem.status}'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
