class Case {
  final String id;
  final String caseNo;
  final String handleBy;
  final String applicant;
  final String opponent;
  final String courtName;
  final DateTime srDate;
  final String cityName;
  final String caseType;
  final String caseCounter;
  final String complainantAdvocate;
  final String respondentAdvocate;
  final DateTime dateOfFiling;
  final DateTime nextDate;

  Case({
    required this.id,
    required this.caseNo,
    required this.handleBy,
    required this.applicant,
    required this.opponent,
    required this.courtName,
    required this.srDate,
    required this.cityName,
    required this.caseType,
    required this.complainantAdvocate,
    required this.respondentAdvocate,
    required this.dateOfFiling,
    required this.nextDate,
    required this.caseCounter,
  });

  factory Case.fromJson(Map<String, dynamic> json) {
    return Case(
      id: json['case_id'] ?? '',
      caseNo: json['case_no'] ?? '',
      handleBy: json['handle_by'] ?? '',
      applicant: json['applicant'] ?? '',
      opponent: json['opp_name'] ?? '',
      courtName: json['court_name'] ?? '',
      srDate: json['sr_date'] != '' && json['sr_date'] != null
          ? DateTime.parse(json['sr_date'])
          : DateTime.parse('0001-01-01'),
      cityName: json['city_name'] ?? '',
      caseType: json['case_type'] ?? '',
      complainantAdvocate: json['complainant_advocate'] ?? '',
      respondentAdvocate: json['respondent_advocate'] ?? '',
      dateOfFiling:
          json['date_of_filing'] != '' && json['date_of_filing'] != null
              ? DateTime.parse(json['date_of_filing'])
              : DateTime.parse('0001-01-01'),
      nextDate: json['next_date'] != '' && json['next_date'] != null
          ? DateTime.parse(json['next_date'])
          : DateTime.parse('0001-01-01'),
      caseCounter: json['case_counter'] ?? '',
    );
  }
}
