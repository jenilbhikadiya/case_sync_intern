import 'package:intl/intl.dart';

class TaskItem {
  final String intern_id;
  final String caseNo;
  final String instruction;
  final String allotedTo;
  final String alloted_to_id;
  final String allotedBy;
  final DateTime? allotedDate;
  final String added_by;
  final DateTime? expectedEndDate;
  final String status;
  final String task_id;
  final String stage;
  final String case_id;
  final String stage_id;
  final String case_type;

  TaskItem({
    required this.intern_id,
    required this.caseNo,
    required this.instruction,
    required this.allotedTo,
    required this.alloted_to_id,
    required this.allotedBy,
    required this.added_by,
    this.allotedDate,
    this.expectedEndDate,
    required this.status,
    required this.task_id,
    required this.stage,
    required this.case_id,
    required this.stage_id,
    required this.case_type,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      intern_id: json['intern_id'] ?? '',
      caseNo: json['case_no'] ?? '',
      instruction: (json['instruction'] ?? '').trim(),
      allotedTo: json['alloted_to'] ?? '',
      alloted_to_id: json['alloted_to_id'] ?? '',
      allotedBy: json['alloted_by'] ?? '',
      added_by: json['added_by'] ?? '',
      allotedDate: json['alloted_date'] != null
          ? DateTime.tryParse(json['alloted_date'])
          : null,
      expectedEndDate: json['expected_end_date'] != null
          ? DateTime.tryParse(json['expected_end_date'])
          : null,
      status: json['status'] ?? '',
      task_id: json['task_id'] ?? '',
      stage: json['stage'] ?? '',
      case_id: json['case_id'] ?? '',
      stage_id: json['stage_id'] ?? '',
      case_type: json['case_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intern_id': intern_id,
      'caseNo': caseNo,
      'instruction': instruction,
      'allotedTo': allotedTo,
      'alloted_to_id': alloted_to_id,
      'allotedBy': allotedBy,
      'added_by': added_by,
      'allotedDate': allotedDate?.toIso8601String(),
      'expectedEndDate': expectedEndDate?.toIso8601String(),
      'status': status,
      'task_id': task_id,
      'stage': stage,
      'case_id': case_id,
      'stage_id': stage_id,
      'case_type': case_type,
    };
  }

  /// Get formatted date in `dd/MM/yy` format
  String get formattedAllotedDate => allotedDate != null
      ? DateFormat('dd/MM/yyyy').format(allotedDate!)
      : 'N/A';

  String get formattedExpectedEndDate => expectedEndDate != null
      ? DateFormat('dd/MM/yyyy').format(expectedEndDate!)
      : 'N/A';
}
