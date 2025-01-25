import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/case_list.dart';

class CaseCard extends StatelessWidget {
  final CaseListData caseItem;
  final int srNo; // Sr No parameter
  final bool isHighlighted;
  final bool isTask;

  const CaseCard({
    super.key,
    required this.caseItem,
    required this.srNo,
    this.isHighlighted = false,
    this.isTask = false,
  });

  Future<void> fetchCaseHistory(BuildContext context) async {
    final String apiUrl =
        "https://pragmanxt.com/case_sync/services/intern/v1/index.php/case_history_view";
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Accept": "*/*",
        "User-Agent": "Apidog/1.0.0 (https://apidog.com)",
        "Connection": "keep-alive",
        "Host": "pragmanxt.com",
      },
      body: {
        "case_id": caseItem.caseNo, // Replace with caseItem.caseNo
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final caseDetails = data['data'][0];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CaseDetailsScreen(caseDetails: caseDetails),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch case history.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        fetchCaseHistory(context);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        color: isHighlighted ? Colors.black : Colors.white,
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
                'Sr No: $srNo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Case No: ${caseItem.caseNo}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Company: ${caseItem.companyName}',
                style: TextStyle(
                  fontSize: 14,
                  color: isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Court Name: ${caseItem.courtName}, ${caseItem.cityName}',
                style: TextStyle(
                  fontSize: 14,
                  color: isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Summon Date: ${caseItem.srDate.day.toString().padLeft(2, '0')}/'
                '${caseItem.srDate.month.toString().padLeft(2, '0')}/'
                '${caseItem.srDate.year}',
                style: TextStyle(
                  fontSize: 14,
                  color: isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Status: ${caseItem.status}',
                style: TextStyle(
                  fontSize: 14,
                  color: isHighlighted ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CaseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> caseDetails;

  const CaseDetailsScreen({Key? key, required this.caseDetails})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Case No: ${caseDetails['case_no']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Intern Name: ${caseDetails['intern_name']}'),
            Text('Advocate: ${caseDetails['advocate_name']}'),
            Text('Stage: ${caseDetails['stage_name']}'),
            Text('Remarks: ${caseDetails['remarks']}'),
            Text('DOS: ${caseDetails['dos']}'),
            Text('Next Date: ${caseDetails['nextdate']}'),
            Text('Status: ${caseDetails['status']}'),
          ],
        ),
      ),
    );
  }
}
