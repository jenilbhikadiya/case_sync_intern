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
  final String caseTypeName;
  final String status;
  final String summonDate;

  CaseListData({
    required this.id,
    required this.caseNo,
    required this.handleBy,
    required this.applicant,
    required this.opponent,
    required this.courtName,
    required this.srDate,
    required this.cityName,
    required this.companyName,
    required this.caseTypeName,
    required this.status,
    required this.summonDate,
  });

  factory CaseListData.fromJson(Map<String, dynamic> json) {
    return CaseListData(
      id: json['id'] ?? '',
      caseNo: json['case_no'] ?? '',
      handleBy: json['handle_by'] ?? '',
      applicant: json['applicant'] ?? '',
      opponent: json['opp_name'] ?? '',
      courtName: json['court_name'] ?? '',
      srDate: DateTime.now(), // Default to now if no value is provided
      cityName: json['city_name'] ?? '',
      companyName: json['company_name'] ?? '',
      caseTypeName: json['case_type_name'] ?? '',
      status: json['status'] ?? '',
      summonDate: json['summon_date'] ?? '',
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
