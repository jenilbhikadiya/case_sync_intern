import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/screens/Case_History/view_docs.dart';

import '../../components/basicUIcomponent.dart';
import '../../components/list_app_bar.dart';
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
  List<dynamic> _caseHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchCaseHistory();
  }

  Future<void> _fetchCaseHistory() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/case_history_view'),
        body: {'case_id': widget.caseId},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data['success'] == true && data['data'] != null) {
            _caseHistory = data['data'];
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

  void _viewDocument() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewDocs(
          caseId: widget.caseId,
          caseNo: widget.caseNo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ListAppBar(
        onSearchPressed: () {},
        title: 'View Case History',
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCaseHistory,
        color: AppTheme.getRefreshIndicatorColor(Theme.of(context).brightness),
        backgroundColor: AppTheme.getRefreshIndicatorBackgroundColor(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(),
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
                            children: _caseHistory.map((caseData) {
                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(
                                      color: Colors.black,
                                      style: BorderStyle.solid),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Intern: ${caseData['intern_name']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                      const SizedBox(height: 0),
                                      Text(
                                          'Advocate: ${caseData['advocate_name']}'),
                                      Text('Stage: ${caseData['stage_name']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text('Remarks: ${caseData['remarks']}'),
                                      Text(
                                          'Date of Summon: ${caseData['fdos']}'),
                                      Text(
                                          'Next Date: ${caseData['nextdate']}'),
                                      Text('Status: ${caseData['status']}'),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Add functionality for adding next date
                      },
                      child: const Text('Add Next Date'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Add functionality for adding next stage
                      },
                      child: const Text('Add Next Stage'),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _viewDocument,
                  child: const Text('View Document'),
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
