import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/case.dart';
import '../screens/Case_History/case_info.dart';

class TodaysCaseCard extends StatelessWidget {
  final Case caseItem;
  final bool isHighlighted;

  const TodaysCaseCard({
    super.key,
    required this.caseItem,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('Tapped Case:');
        print('Case ID: ${caseItem.id}');
        print('Case No: ${caseItem.caseNo}');
        print('Applicant: ${caseItem.applicant}');
        print('Opponent: ${caseItem.opponent}');
        print('Court: ${caseItem.courtName}');
        print('City: ${caseItem.cityName}');
        print('Next Date: ${caseItem.nextDate}');
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CaseInfoPage(
              caseId: caseItem.id,
              caseNo: caseItem.caseNo,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        color: isHighlighted ? Colors.black : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Case Number
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
                    // Applicant vs Opponent
                    Text(
                      '${caseItem.applicant} vs ${caseItem.opponent}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isHighlighted ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Summon Date
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
                    // Court
                    Text(
                      'Court: ${caseItem.courtName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isHighlighted ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // City
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
            ],
          ),
        ),
      ),
    );
  }
}
