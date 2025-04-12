import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

  Color _getStatusColor(String status) {
    if (status.toLowerCase() == 'completed') {
      return Colors.green.shade400;
    } else if (status.toLowerCase() == 'pending') {
      return Colors.orange.shade400;
    } else if (status.toLowerCase() == 'in progress') {
      return Colors.blue.shade400;
    } else {
      return Colors.grey;
    }
  }

  TableRow _buildTableRow(IconData icon, String label, Widget valueWidget,
      {bool isTitle = false}) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    fontWeight: isTitle ? FontWeight.bold : FontWeight.w500,
                    color: Colors.black87,
                    fontSize: 15),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: DefaultTextStyle(
            style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: isTitle ? FontWeight.bold : FontWeight.normal),
            child: valueWidget,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ListAppBar(
        onSearchPressed: () {},
        showSearch: false,
        title: 'Case History',
      ),
      body: RefreshIndicator(
        onRefresh: _fetchInternTaskList,
        color: AppTheme.getRefreshIndicatorColor(Theme.of(context).brightness),
        backgroundColor: AppTheme.getRefreshIndicatorBackgroundColor(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.black))
              : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage))
                  : Column(
                      children: _caseHistory.asMap().entries.map((entry) {
                        int index = entry.key + 1;
                        TaskItem taskItem = entry.value;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 5.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.5),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Table(
                              columnWidths: const {
                                0: IntrinsicColumnWidth(),
                                1: FlexColumnWidth(),
                              },
                              border: TableBorder.all(
                                color: Colors.grey.shade200,
                                width: 0.3,
                              ),
                              children: [
                                _buildTableRow(
                                  Icons.format_list_numbered,
                                  'SR. No.',
                                  Text(index.toString(),
                                      style: const TextStyle(fontSize: 16)),
                                  isTitle: true,
                                ),
                                _buildTableRow(
                                  Icons.text_snippet_outlined,
                                  'Instruction',
                                  Text(taskItem.instruction),
                                ),
                                _buildTableRow(
                                  Icons.person_outline,
                                  'Alloted To',
                                  Text(taskItem.allotedTo),
                                ),
                                _buildTableRow(
                                  Icons.person_outline,
                                  'Alloted By',
                                  Text(taskItem.allotedBy),
                                ),
                                _buildTableRow(
                                  Icons.calendar_today_outlined,
                                  'Alloted Date',
                                  Text(taskItem.formattedAllotedDate),
                                ),
                                _buildTableRow(
                                  Icons.event_available_outlined,
                                  'End Date',
                                  Text(taskItem.formattedExpectedEndDate),
                                ),
                                _buildTableRow(
                                  Icons.label_outline,
                                  'Stage',
                                  Text(taskItem.stage),
                                ),
                                _buildTableRow(
                                  Icons.info_outline,
                                  'Status',
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(taskItem.status)
                                            .withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        taskItem.status.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
        ),
      ),
    );
  }
}
