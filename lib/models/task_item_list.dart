class TaskItem {
  final String intern_id;
  final String caseNo;
  final String instruction;
  final String allotedTo;
  final String allotedBy;
  final DateTime? allotedDate; // Nullable to handle missing or invalid dates
  final DateTime?
      expectedEndDate; // Nullable to handle missing or invalid dates
  final String status;
  final String task_id;
  final String stage;
  final String case_id;
  final String stage_id;

  TaskItem({
    required this.intern_id,
    required this.caseNo,
    required this.instruction,
    required this.allotedTo,
    required this.allotedBy,
    this.allotedDate,
    this.expectedEndDate,
    required this.status,
    required this.task_id,
    required this.stage,
    required this.case_id,
    required this.stage_id,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      intern_id: json['intern_id'] ?? '',
      caseNo: json['case_no'] ?? '',
      instruction: (json['instruction'] ?? '').trim(),
      allotedTo: json['alloted_to'] ?? '',
      allotedBy: json['alloted_by'] ?? '',
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
    );
  }
}
