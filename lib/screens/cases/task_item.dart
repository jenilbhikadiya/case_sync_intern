class TaskItem {
  final String id;
  final String caseNo;
  final String instruction;
  final String allotedTo;
  final String allotedBy;
  final DateTime allotedDate;
  final DateTime expectedEndDate;
  final String status;

  TaskItem({
    required this.id,
    required this.caseNo,
    required this.instruction,
    required this.allotedTo,
    required this.allotedBy,
    required this.allotedDate,
    required this.expectedEndDate,
    required this.status,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'],
      caseNo: json['case_no'],
      instruction: json['instruction'].trim(),
      allotedTo: json['alloted_to'],
      allotedBy: json['alloted_by'],
      allotedDate: DateTime.parse(json['alloted_date']),
      expectedEndDate: DateTime.parse(json['expected_end_date']),
      status: json['status'],
    );
  }
}
