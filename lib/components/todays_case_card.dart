import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intern_side/screens/Case_History/case_info.dart';
import 'package:intl/intl.dart';

import '../models/case_list.dart';
import '../utils/priority_dialog.dart';

class UpcomingCaseCard extends StatefulWidget {
  final CaseListData caseItem;
  final bool isHighlighted;

  const UpcomingCaseCard({
    super.key,
    required this.caseItem,
    required this.isHighlighted,
  });

  @override
  UpcomingCaseCardState createState() => UpcomingCaseCardState();
}

class UpcomingCaseCardState extends State<UpcomingCaseCard> {
  void _showPriorityDialog() {
    showDialog(
      context: context,
      builder: (context) => PriorityDialog(
        onPrioritySelected: (priority) {
          setState(() {
            widget.caseItem.priorityNumber = priority;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CaseInfoPage(
              caseId: widget.caseItem.id,
              caseNo: widget.caseItem.caseNo,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        color: widget.isHighlighted ? Colors.black : Colors.white,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Case No: ${widget.caseItem.caseNo}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: widget.isHighlighted ? Colors.white : Colors.black,
                    ),
                  ),
                  (DateFormat("dd-MM-yyyy").format(widget.caseItem.nextDate) ==
                          DateFormat("dd-MM-yyyy").format(DateTime.now()))
                      ? (widget.caseItem.priorityNumber == null)
                          ? GestureDetector(
                              onTap: _showPriorityDialog,
                              child: Icon(
                                Icons.add_circle,
                                color: widget.isHighlighted
                                    ? Colors.white
                                    : Colors.black,
                                size: 32,
                              ),
                            )
                          : Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.isHighlighted
                                    ? Colors.black
                                    : Colors.white,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${widget.caseItem.priorityNumber}',
                                style: TextStyle(
                                  color: widget.isHighlighted
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            )
                      : SizedBox.shrink()
                ],
              ),
              Divider(
                color: widget.isHighlighted ? Colors.white : Colors.black,
              ),
              Text(
                '${widget.caseItem.applicant.capitalize} vs ${widget.caseItem.opponent.capitalize}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Summon Date: ${widget.caseItem.srDate.day.toString().padLeft(2, '0')}/'
                '${widget.caseItem.srDate.month.toString().padLeft(2, '0')}/'
                '${widget.caseItem.srDate.year}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Court: ${widget.caseItem.courtName}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'City: ${widget.caseItem.cityName}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                (widget.caseItem.caseCounter.isEmpty ||
                        widget.caseItem.caseCounter == 'null')
                    ? "Case Counter: Not Available"
                    : "Case Counter: ${widget.caseItem.caseCounter} days",
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
