import 'package:flutter/material.dart';
import '../../models/case.dart';

class TodaysCaseCard extends StatelessWidget {
  final Case caseItem;

  const TodaysCaseCard({super.key, required this.caseItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Case Number
            Text(
              'Case No: ${caseItem.caseNo}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),

            // Applicant vs Opponent
            Text(
              '${caseItem.applicant} vs ${caseItem.oppName}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),

            // Court Name
            Text(
              'Court: ${caseItem.courtName}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            // Case Type
            const SizedBox(height: 4),
            Text(
              'Case Type: ${caseItem.caseType}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            // City Name
            const SizedBox(height: 4),
            Text(
              'City: ${caseItem.cityName}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            // Complainant Advocate
            const SizedBox(height: 4),
            Text(
              'Complainant Advocate: ${caseItem.complainantAdvocate}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            // Respondent Advocate
            const SizedBox(height: 4),
            Text(
              'Respondent Advocate: ${caseItem.respondentAdvocate}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
