class CaseListData {
  final String id;
  final String caseNo;
  final String handleBy;
  final String applicant;
  final String opponent;
  final String courtName;
  final DateTime srDate;
  final String cityName;

  CaseListData({
    required this.id,
    required this.caseNo,
    required this.handleBy,
    required this.applicant,
    required this.opponent,
    required this.courtName,
    required this.srDate,
    required this.cityName,
  });

  factory CaseListData.fromJson(Map<String, dynamic> json) {
    return CaseListData(
      id: json['id'],
      caseNo: json['case_no'] ?? '',
      handleBy: json['handle_by'] ?? '',
      applicant: json['applicant'] ?? '',
      opponent: json['opp_name'] ?? '',
      courtName: json['court_name'] ?? '',
      srDate: DateTime.parse(json['sr_date']),
      cityName: json['city_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_no': caseNo,
      'handle_by': handleBy,
      'applicant': applicant,
      'opp_name': opponent,
      'court_name': courtName,
      'sr_date': srDate.toIso8601String(),
      'city_name': cityName,
    };
  }
}
