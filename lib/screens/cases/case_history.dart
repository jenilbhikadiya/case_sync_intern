import 'package:flutter/material.dart';

class CaseHistoryScreen extends StatelessWidget {
  const CaseHistoryScreen({super.key});

  static const List<Map<String, String>> caseHistories = [
    {'caseNumber': '12345', 'allocatedBy': 'Dr. John Doe', 'allocatedDate': '01/18/2025'},
    {'caseNumber': '67890', 'allocatedBy': 'Dr. Jane Smith', 'allocatedDate': '01/17/2025'},
    // Add more case histories as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case History'),
      ),
      body: caseHistories.isEmpty
          ? Center(
        child: Text(
          'No case history available',
          style: TextStyle(fontSize: 24),
        ),
      )
          : ListView.builder(
        itemCount: caseHistories.length,
        itemBuilder: (context, index) {
          final caseHistory = caseHistories[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caseHistory['caseNumber']!,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Allocated by: ${caseHistory['allocatedBy']}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Allocated Date: ${caseHistory['allocatedDate']}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
