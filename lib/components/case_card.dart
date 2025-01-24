import 'package:flutter/material.dart';

import '../models/case_list.dart';

class CaseCard extends StatelessWidget {
  final CaseListData caseItem;
  final int srNo; // Added Sr No parameter
  final bool isHighlighted;
  final bool isTask;

  const CaseCard({
    super.key,
    required this.caseItem,
    required this.srNo, // Required Sr No parameter
    this.isHighlighted = false,
    this.isTask = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigation logic can be added here if required.
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
