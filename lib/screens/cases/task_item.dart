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
}
