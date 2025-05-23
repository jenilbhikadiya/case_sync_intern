import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intern_side/screens/Case_History/case_info.dart';
import 'package:intern_side/screens/Case_History/proceed_case.dart';
import 'package:intern_side/screens/Case_History/view_case_history.dart';
import 'package:intern_side/screens/Case_History/view_docs.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/utils/constants.dart';
import '../models/case_list.dart';
import '../screens/Case_History/ProceedHistory.dart';
import '../screens/add_task/add_task_screen.dart';
import '../services/shared_pref.dart';

class CaseTaskCard extends StatefulWidget {
  final CaseListData caseItem;
  final bool isHighlighted;
  final bool isTask;

  const CaseTaskCard({
    super.key,
    required this.caseItem,
    this.isHighlighted = false,
    this.isTask = false,
  });

  @override
  _CaseTaskCardState createState() => _CaseTaskCardState();
}

class _CaseTaskCardState extends State<CaseTaskCard> {
  bool isLoading = false;
  String errorMessage = '';
  dynamic _userData;
  List<CaseListData> taskList = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      setState(() => isLoading = true);

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
    String url = '$baseUrl/intern_task_list';

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
                .map((task) => CaseListData.fromJson(task))
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

  void _showDropdownMenu(BuildContext context, CaseListData caseListData) {
    bool isRealloted = (caseListData.status.toLowerCase() == 're_alloted' ||
        caseListData.status.toLowerCase() == 'completed');

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Case No: ${caseListData.caseNo}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.document_scanner),
                title: const Text('View Docs'),
                enabled: !isRealloted,
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewDocs(
                        caseId: caseListData.id,
                        caseNo: caseListData.caseNo,
                      ),
                    ),
                  );
                  if (result == true) {
                    fetchTasks();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('View Case Tasks'),
                enabled: !isRealloted,
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewCaseHistoryScreen(
                        caseId: caseListData.id,
                        caseNo: caseListData.caseNo,
                      ),
                    ),
                  );
                  if (result == true) {
                    fetchTasks();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Case Info'),
                enabled: !isRealloted,
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CaseInfoPage(
                        caseId: caseListData.id,
                        caseNo: caseListData.caseNo,
                      ),
                    ),
                  );
                  if (result == true) {
                    fetchTasks();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Proceed Case'),
                enabled: !isRealloted,
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProceedCaseAdd(
                        caseId: caseListData.id,
                        caseNo: caseListData.caseNo,
                      ),
                    ),
                  );
                  if (result == true) {
                    fetchTasks();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cases_sharp),
                title: const Text('Proceed History'),
                enabled: !isRealloted,
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewProceedCaseHistoryScreen(
                        caseId: caseListData.id,
                        caseNo: caseListData.caseNo,
                      ),
                    ),
                  );
                  if (result == true) {
                    fetchTasks();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTaskScreen(
              caseNumber: widget.caseItem.caseNo,
              caseType: '',
              caseId: widget.caseItem.id,
            ),
          ),
        );
        if (result == true) {
          fetchTasks();
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        color: widget.isHighlighted ? Colors.black : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, style: BorderStyle.solid),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Case No: ${widget.caseItem.caseNo}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              Divider(
                  color: widget.isHighlighted ? Colors.white : Colors.black),
              const SizedBox(height: 5),
              Text(
                'Company: ${widget.caseItem.companyName}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Court: ${widget.caseItem.courtName}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'City: ${widget.caseItem.cityName}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Summon Date: ${widget.caseItem.srDate.day.toString().padLeft(2, '0')}/'
                '${widget.caseItem.srDate.month.toString().padLeft(2, '0')}/'
                '${widget.caseItem.srDate.year}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
