// lib/models/proceed_case.dart
class ProceedCase {
  final String id;
  final String caseId;
  final String nextStage;
  final String nextDate;
  final String remarks;
  final String insertedBy;
  final String dateOfCreation;
  final String stage;
  final String inserted_by_name;

  ProceedCase({
    required this.id,
    required this.caseId,
    required this.nextStage,
    required this.nextDate,
    required this.remarks,
    required this.insertedBy,
    required this.dateOfCreation,
    required this.stage,
    required this.inserted_by_name,
  });

  factory ProceedCase.fromJson(Map<String, dynamic> json) {
    return ProceedCase(
      id: json['id'] ?? '',
      caseId: json['case_id'] ?? '',
      nextStage: json['next_stage'] ?? '',
      nextDate: json['next_date'] ?? '',
      remarks: json['remarks'] ?? '',
      insertedBy: json['inserted_by'] ?? '',
      dateOfCreation: json['date_of_creation'] ?? '',
      stage: json['stage'] ?? '',
      inserted_by_name: json['inserted_by_name'] ?? '',
    );
  }
}
