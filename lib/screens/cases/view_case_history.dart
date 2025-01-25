import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ViewCaseHistoryScreen extends StatefulWidget {
  final String caseId; // Accepting case ID from the previous page

  const ViewCaseHistoryScreen({super.key, required this.caseId});

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
        Uri.parse(
          'https://pragmanxt.com/case_sync/services/intern/v1/index.php/case_history_view',
        ),
        headers: {
          'User-Agent': 'Apidog/1.0.0 (https://apidog.com)',
          'Accept': '*/*',
          'Host': 'pragmanxt.com',
        },
        body: {'case_id': widget.caseId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _caseHistory = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'No data found.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load case history.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Case History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  itemCount: _caseHistory.length,
                  itemBuilder: (context, index) {
                    final caseData = _caseHistory[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 10.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(
                          color: Colors.black,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stage: ${caseData['stage_name']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Remarks: ${caseData['remarks']}'),
                            Text('Date of Summon: ${caseData['fdos']}'),
                            Text('Next Date: ${caseData['nextdate']}'),
                            Text('Status: ${caseData['status']}'),
                            Text('Advocate: ${caseData['advocate_name']}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
