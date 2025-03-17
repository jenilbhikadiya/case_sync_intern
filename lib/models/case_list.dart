class CaseListData {
  final String id;
  final String caseNo;
  final String handleBy;
  final String applicant;
  final String opponent;
  final String courtName;
  final DateTime srDate;
  final String cityName;
  final String companyName;
  final String caseType;
  final String caseCounter;
  final String status;
  final String complainantAdvocate;
  final String respondentAdvocate;
  final DateTime dateOfFiling;
  final DateTime nextDate;
  int? priorityNumber;

  CaseListData({
    required this.id,
    required this.caseNo,
    required this.handleBy,
    required this.applicant,
    required this.opponent,
    required this.courtName,
    required this.srDate,
    required this.status,
    required this.cityName,
    required this.companyName,
    required this.caseType,
    required this.complainantAdvocate,
    required this.respondentAdvocate,
    required this.dateOfFiling,
    required this.nextDate,
    required this.caseCounter,
    this.priorityNumber,
  });

  factory CaseListData.fromJson(Map<String, dynamic> json) {
    return CaseListData(
      id: json['id'] ?? json['case_id'].toString() ?? '',
      caseNo: json['case_no'] ?? '',
      handleBy: json['handle_by'] ?? '',
      applicant: json['applicant'] ?? '',
      opponent: json['opp_name'] ?? '',
      status: json['status'] ?? '',
      courtName: json['court_name'] ?? '',
      srDate: (json['sr_date'] == null ||
              json['sr_date'].toString() == '0000-00-00' ||
              json['sr_date'].toString().isEmpty)
          ? DateTime.parse('0001-01-01')
          : DateTime.parse(json['sr_date']),
      cityName: json['city_name'] ?? '',
      companyName: json['company_name'] ?? '',
      caseType: json['case_type'] ?? '',
      complainantAdvocate: json['complainant_advocate'] ?? '',
      respondentAdvocate: json['respondent_advocate'] ?? '',
      dateOfFiling: (json['date_of_filing'] == null ||
              json['date_of_filing'].toString() == '0000-00-00' ||
              json['date_of_filing'].toString().isEmpty)
          ? DateTime.parse('0001-01-01')
          : DateTime.parse(json['date_of_filing']),
      nextDate: (json['next_date'] == null ||
              json['next_date'].toString() == '0000-00-00' ||
              json['next_date'].toString().isEmpty)
          ? DateTime.parse('0001-01-01')
          : DateTime.parse(json['next_date']),
      caseCounter: json['case_counter'].toString(),
      priorityNumber: json['priority_number'],
    );
  }
}
