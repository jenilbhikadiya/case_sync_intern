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

  const ViewCaseHistoryScreen({
    super.key,
    required this.caseId,
    required this.caseNo,
  });

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
                .map((taskData) =>
                    TaskItem.fromJson(taskData as Map<String, dynamic>))
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: ListAppBar(
        onSearchPressed: () {},
        showSearch: false,
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
                              int index = entry.key + 1; // Serial number
                              TaskItem taskItem = entry.value;
                              return GestureDetector(
                                onTap: () {},
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
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .grey[200], // Light grey background
                                        borderRadius: BorderRadius.circular(
                                            20), // Match card's border radius
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Sr No: $index',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18)),
                                          const SizedBox(height: 8),
                                          Table(
                                            border: TableBorder.all(
                                                color: Colors.black),
                                            columnWidths: const {
                                              0: FlexColumnWidth(
                                                  2), // Key column
                                              1: FlexColumnWidth(
                                                  3), // Value column
                                            },
                                            children: [
                                              _buildTableRow(
                                                  'Case No', taskItem.caseNo),
                                              _buildTableRow('Instruction',
                                                  taskItem.instruction),
                                              _buildTableRow('Alloted To',
                                                  taskItem.allotedTo),
                                              _buildTableRow('Alloted By',
                                                  taskItem.allotedBy),
                                              _buildTableRow(
                                                  'Alloted Date',
                                                  taskItem
                                                      .formattedAllotedDate),
                                              _buildTableRow(
                                                  'Expected End Date',
                                                  taskItem
                                                      .formattedExpectedEndDate),
                                              _buildTableRow(
                                                  'Stage', taskItem.stage),
                                              TableRow(children: [
                                                const Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text('Status:',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: getStatusColor(
                                                          taskItem.status),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        taskItem.status,
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                            ],
                                          ),
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

TableRow _buildTableRow(String key, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(key,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    ],
  );
}
