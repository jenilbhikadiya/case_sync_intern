import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/case_list.dart';
import '../services/api_service.dart'; // Ensure correct import path for your API service

final Map<String, Map<String, List<CaseListData>>> caseData = {};
final List<String> years = []; // New variable to store distinct years

Future<void> populateCaseData() async {
  try {
    caseData.clear();
    years.clear();

    // Fetch data from API
    final List<CaseListData> cases = await CaseApiService.fetchCaseList();

    if (cases.isEmpty) {
      return; // Exit early if no data
    }

    for (var caseItem in cases) {
      String year = caseItem.dateOfFiling.year.toString();
      String month = DateFormat('MMMM').format(caseItem.dateOfFiling);

      if (!years.contains(year)) {
        years.add(year);
      }

      caseData.putIfAbsent(year, () => {});
      caseData[year]!.putIfAbsent(month, () => []);

      caseData[year]![month]!.add(caseItem);
    }

    years.sort();
  } catch (e) {
    // Handle error
  }
}

List<CaseListData> getCaseDataForMonth(String year, String month) {
  return caseData[year]?[month] ?? [];
}
