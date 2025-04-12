import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/screens/Case_History/case_info.dart';
import 'package:intl/intl.dart';

import '../models/case_list.dart';
import '../utils/constants.dart';
import '../utils/priority_dialog.dart';

class UpcomingCaseCard extends StatefulWidget {
  final CaseListData caseItem;
  final bool isHighlighted;
  final Function(DateTime date) updateCases;

  const UpcomingCaseCard({
    super.key,
    required this.caseItem,
    required this.isHighlighted,
    required this.updateCases,
  });

  @override
  UpcomingCaseCardState createState() => UpcomingCaseCardState();
}

class UpcomingCaseCardState extends State<UpcomingCaseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showPriorityDialog() {
    showDialog(
      context: context,
      builder: (context) => PriorityDialog(
        onPrioritySelected: updatePriority,
        caseNumber: widget.caseItem.caseNo, // Passing the case number here
      ),
    );
  }

  Future<void> updatePriority(int? priority, String remark) async {
    if (widget.caseItem.priorityNumber == null && priority != null) {
      await addPrioritySequence(widget.caseItem.id, priority, "admin", remark);
    } else if (widget.caseItem.priorityNumber != null && priority == null) {
      await deletePrioritySequence(widget.caseItem.priorityId);
    } else if (widget.caseItem.priorityNumber != null && priority != null) {
      await updatePrioritySequence(widget.caseItem.id,
          widget.caseItem.priorityId, priority, "admin", remark);
    }
  }

  Future<void> addPrioritySequence(
      String caseId, int sequence, String addedBy, String remark) async {
    try {
      final url = Uri.parse("$baseUrl/add_sequence");
      final request = http.MultipartRequest('POST', url);
      request.fields['data'] = jsonEncode({
        'case_id': caseId,
        'sequence': sequence.toString(),
        'added_by': addedBy,
        'remark': remark,
      });
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['success'] == true) {
          await widget.updateCases(widget.caseItem.nextDate);
        } else {
          print("Add sequence failed: ${data['message'] ?? 'Unknown error'}");
        }
      } else {
        print(
            "Add sequence HTTP error: ${response.statusCode} - $responseBody");
      }
    } catch (e) {
      print("Error adding priority sequence: $e");
    }
  }

  Future<void> deletePrioritySequence(String? sequenceId) async {
    if (sequenceId == null) {
      print("Cannot delete sequence: sequenceId is null");
      return;
    }
    try {
      final url = Uri.parse("$baseUrl/delete_sequence");
      final request = http.MultipartRequest('POST', url);
      request.fields['data'] = jsonEncode({
        'id': sequenceId,
      });
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['success'] == true) {
          await widget.updateCases(widget.caseItem.nextDate);
        } else {
          print(
              "Delete sequence failed: ${data['message'] ?? 'Unknown error'}");
        }
      } else {
        print(
            "Delete sequence HTTP error: ${response.statusCode} - $responseBody");
      }
    } catch (e) {
      print("Error deleting priority sequence: $e");
    }
  }

  Future<void> updatePrioritySequence(String caseId, String? sequenceId,
      int sequence, String addedBy, String remark) async {
    if (sequenceId == null) {
      print("Cannot update sequence: sequenceId is null");
      return;
    }
    try {
      final url = Uri.parse("$baseUrl/edit_sequence");
      final request = http.MultipartRequest('POST', url);
      request.fields['data'] = jsonEncode({
        'id': sequenceId,
        'case_id': caseId,
        'sequence': sequence.toString(),
        'added_by': addedBy,
        'remark': remark,
      });
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['success'] == true) {
          await widget.updateCases(widget.caseItem.nextDate);
        } else {
          print(
              "Update sequence failed: ${data['message'] ?? 'Unknown error'}");
        }
      } else {
        print(
            "Update sequence HTTP error: ${response.statusCode} - $responseBody");
      }
    } catch (e) {
      print("Error updating priority sequence: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedNextDate =
        DateFormat("dd-MM-yyyy").format(widget.caseItem.nextDate);
    final formattedTodayDate = DateFormat("dd-MM-yyyy").format(DateTime.now());
    final bool isToday = formattedNextDate == formattedTodayDate;

    // Determine the priority remark to display
    String priorityRemarkText = widget.caseItem.priorityRemark != null &&
            widget.caseItem.priorityRemark!.isNotEmpty
        ? widget.caseItem.priorityRemark!
        : " "; // Print a space if null or empty

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                CaseInfoPage(
              caseId: widget.caseItem.id,
              caseNo: widget.caseItem.caseNo,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.1);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          ),
        );
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Padding(
            // Added Padding for the card margin
            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
            child: Container(
              decoration: BoxDecoration(
                color: widget.isHighlighted
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Column(
                          children: [
                            Text(
                              'Case No: ${widget.caseItem.caseNo}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: widget.isHighlighted
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            Text(
                              'Remark: $priorityRemarkText', // Display the determined remark
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: widget.isHighlighted
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        )),
                        const SizedBox(width: 12),
                        if (isToday)
                          InkWell(
                            onTap: _showPriorityDialog,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                              ),
                              alignment: Alignment.center,
                              child: widget.caseItem.priorityNumber == null
                                  ? const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : FittedBox(
                                      child: Text(
                                        '${widget.caseItem.priorityNumber}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      // Added Padding for the table inside the card
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTableRow(
                            'Parties',
                            '${GetStringUtils(widget.caseItem.applicant).capitalize} vs ${GetStringUtils(widget.caseItem.opponent).capitalize}',
                            widget.isHighlighted,
                            icon: Icons.people_outline,
                          ),
                          _buildTableRow(
                            'Summon',
                            DateFormat("dd/MM/yyyy")
                                .format(widget.caseItem.srDate),
                            widget.isHighlighted,
                            icon: Icons.calendar_today_outlined,
                          ),
                          _buildTableRow(
                            'Court',
                            widget.caseItem.courtName,
                            widget.isHighlighted,
                            icon: Icons.location_city_outlined,
                          ),
                          _buildTableRow(
                            'City',
                            widget.caseItem.cityName,
                            widget.isHighlighted,
                            icon: Icons.map_outlined,
                          ),
                          if (widget.caseItem.caseCounter.isNotEmpty &&
                              widget.caseItem.caseCounter != 'null')
                            _buildTableRow(
                              'Counter',
                              "${widget.caseItem.caseCounter} days",
                              widget.isHighlighted,
                              icon: Icons.timer_outlined,
                            ),
                          if (widget.caseItem.priorityRemark != null &&
                              widget.caseItem.priorityRemark!.isNotEmpty)
                            _buildTableRow(
                              'Remark',
                              "${widget.caseItem.priorityRemark}",
                              widget.isHighlighted,
                              isRemark: true,
                              icon: Icons.sticky_note_2_outlined,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(String label, String value, bool isHighlighted,
      {bool isRemark = false, IconData? icon}) {
    final textColor = isHighlighted ? Colors.white70 : Colors.black54;
    final valueColor = isHighlighted ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(icon, size: 16, color: textColor),
            ),
          SizedBox(
            width: 75,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isRemark ? 13 : 15,
                color: valueColor,
                fontStyle: isRemark ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
