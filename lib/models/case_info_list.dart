import 'package:intl/intl.dart';

class CaseInfoDetail {
  final String caseNo;
  final String year;
  final String caseType;
  final String stageName;
  final String companyName;
  final String advocateName;
  final String applicant;
  final String opponentName;
  final String courtName;
  final String cityName;
  final DateTime? nextDate;
  final String nextStage;
  final DateTime? summonDate;
  final String complainantAdvocate;
  final String respondentAdvocate;
  final DateTime? dateOfFiling;
  final String caseCounter;

  CaseInfoDetail({
    required this.caseNo,
    required this.year,
    required this.caseType,
    required this.stageName,
    required this.companyName,
    required this.advocateName,
    required this.applicant,
    required this.opponentName,
    required this.courtName,
    required this.cityName,
    this.nextDate,
    required this.nextStage,
    this.summonDate,
    required this.complainantAdvocate,
    required this.respondentAdvocate,
    this.dateOfFiling,
    required this.caseCounter,
  });

  factory CaseInfoDetail.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? date) {
      if (date == null || date.isEmpty || date == '0000-00-00') {
        return null;
      }
      try {
        return DateTime.parse(date);
      } catch (_) {
        return null;
      }
    }

    return CaseInfoDetail(
      caseNo: json['case_no'] ?? '-',
      year: json['year'] ?? '-',
      caseType: json['case_type'] ?? '-',
      stageName: json['stage_name'] ?? '-',
      companyName: json['company_name'] ?? '-',
      advocateName: json['advocate_name'] ?? '-',
      applicant: json['applicant'] ?? '-',
      opponentName: json['opp_name'] ?? '-',
      courtName: json['court_name'] ?? '-',
      cityName: json['city_name'] ?? '-',
      nextDate: parseDate(json['next_date']),
      nextStage: json['next_stage'] ?? '-',
      summonDate: parseDate(json['sr_date']),
      complainantAdvocate: json['complainant_advocate'] ?? '-',
      respondentAdvocate: json['respondent_advocate'] ?? '-',
      dateOfFiling: parseDate(json['date_of_filing']),
      caseCounter: json['case_counter'] ?? '-',
    );
  }

  String formatDate(DateTime? date) {
    return date != null ? DateFormat('dd-MM-yyyy').format(date) : '-';
  }

  Map<String, dynamic> toMap() {
    return {
      'Case No': caseNo,
      'Case Year': year,
      'Case Type': caseType,
      'Current Stage': stageName,
      'Next Stage': nextStage,
      'Company Name': companyName,
      'Plaintiff Name': applicant,
      'Opponent Name': opponentName,
      'Complainant Advocate': complainantAdvocate,
      'Respondent Advocate': respondentAdvocate,
      'Court': courtName,
      'City': cityName,
      'Summon Date': formatDate(summonDate),
      'Next Date': formatDate(nextDate),
      'Date Of Filing': formatDate(dateOfFiling),
      'Case Counter': caseCounter,
    };
  }
}
