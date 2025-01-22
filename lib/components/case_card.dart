import 'package:flutter/material.dart';

import '../models/case_list.dart';
// import '../screens/cases/caseinfo.dart';

class CaseCard extends StatelessWidget {
  final CaseListData caseItem;
  final bool isHighlighted;
  final bool isTask;

  const CaseCard({
    super.key,
    required this.caseItem,
    this.isHighlighted = false,
    this.isTask = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => isTask
        //         ? TasksPage(
        //             caseId: caseItem.id,
        //             caseNumber: '',
        //           )
        //         : CaseInfoPage(caseId: caseItem.id),
        //   ),
        // );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        color: isHighlighted ? Colors.black : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.black, style: BorderStyle.solid)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                '${caseItem.applicant} vs ${caseItem.opponent}',
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
                'Court Name: ${caseItem.courtName}, ${caseItem.cityName}',
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
