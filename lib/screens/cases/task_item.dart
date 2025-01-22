class TaskItem {
  final String caseNo;
  final String instruction;
  final String allotedBy;
  final DateTime allotedDate;
  final DateTime endDate;

  TaskItem({
    required this.caseNo,
    required this.instruction,
    required this.allotedBy,
    required this.allotedDate,
    required this.endDate,
  });

  // Factory constructor to create a TaskItem from JSON
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      caseNo: json['case_no'] ?? '', // Ensure no null values
      instruction: json['instruction'] ?? '',
      allotedBy: json['alloted_by'] ?? '',
      allotedDate: DateTime.parse(json['alloted_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }
}
