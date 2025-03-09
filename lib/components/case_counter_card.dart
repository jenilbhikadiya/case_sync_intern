import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/case.dart';
import '../screens/Case_History/case_info.dart';

class CaseCounterCard extends StatelessWidget {
  final Case caseItem;
  final bool isHighlighted;

  const CaseCounterCard({
    super.key,
    required this.caseItem,
    this.isHighlighted = false,
  });

  // Function to get badge color based on days left
  Color getBadgeColor(int daysLeft) {
    if (daysLeft <= 7 && daysLeft >= 0) {
      return Colors.red.shade900;
    } else if (daysLeft <= 15 && daysLeft > 7) {
      return Colors.red;
    } else if (daysLeft <= 30 && daysLeft > 15) {
      return Colors.yellow.shade600;
    } else if (daysLeft <= 45 && daysLeft > 30) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

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
              // Left color badge
              if (caseItem.caseCounter.isNotEmpty)
                Container(
                  width: 10,
                  height: 135,
                  decoration: BoxDecoration(
                    color: getBadgeColor(int.parse(caseItem.caseCounter)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),

              const SizedBox(width: 15), // Space between badge and content

              // Case details
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
                    const SizedBox(height: 5),
                    Text(
                      (caseItem.caseCounter.isEmpty)
                          ? "Case Counter: Not Available"
                          : "Case Counter: ${caseItem.caseCounter} days",
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
