import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/case_list.dart';
import '../screens/cases/view_case_history.dart';

class CaseCard extends StatelessWidget {
  final CaseListData caseItem; // Required case item parameter
  final bool isHighlighted; // Determines if the card is highlighted
  final bool isTask; // Determines if it's a task card

  const CaseCard({
    super.key,
    required this.caseItem, // Required argument
    this.isHighlighted = false,
    this.isTask = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewCaseHistoryScreen(
              caseId: caseItem.id,
              caseNo: caseItem.caseNo,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(
          vertical: 8.0,
        ),
        color: isHighlighted ? Colors.black : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black, style: BorderStyle.solid),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Case No: ${caseItem.caseNo}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              Divider(
                color: isHighlighted ? Colors.white : Colors.black,
              ),
              Text(
                '${caseItem.applicant.capitalize} vs ${caseItem.opponent.capitalize}',
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
                'Court: ${caseItem.courtName}',
                style: TextStyle(
                  fontSize: 14,
                  color: isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'City: ${caseItem.cityName}',
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
