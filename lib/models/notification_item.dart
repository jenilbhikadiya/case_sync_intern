class NotificationItem {
  final String caseNo;
  final String instruction;
  final String allotedBy;
  final DateTime? date; // Nullable to handle missing or invalid dates
  final String task_id;

  NotificationItem({
    required this.caseNo,
    required this.instruction,
    required this.allotedBy,
    this.date,
    required this.task_id,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      caseNo: json['case_no'] ?? '',
      instruction: (json['msg'] ?? '').trim(),
      allotedBy: json['name'] ?? '',
      date:
          json['datetime'] != null ? DateTime.tryParse(json['datetime']) : null,
      task_id: json['task_id'] ?? '',
    );
  }
}
