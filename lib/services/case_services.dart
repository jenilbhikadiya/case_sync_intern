import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/case_list.dart';
import '../services/api_service.dart'; // Ensure correct import path for your API service

final Map<String, Map<String, List<CaseListData>>> caseData = {};
final List<String> years = []; // New variable to store distinct years

Future<void> populateCaseData(String internId) async {
  try {
    caseData.clear();
    years.clear();

    // print('Entered Here');

    // Fetch data from API
    final List<CaseListData> cases =
        await CaseApiService.fetchCaseList(internId);

    // print(cases.length);

    if (cases.isEmpty) {
      // print("No cases found for intern: $internId");
      return; // Exit early if no data
    }

    if (kDebugMode) {
      // print("Fetched cases: ${cases.length}");
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

    // print("Case data populated successfully: ${caseData.length} years loaded.");
  } catch (e) {
    // print("Error populating case data: $e");
  }
}

List<CaseListData> getCaseDataForMonth(String year, String month) {
  return caseData[year]?[month] ?? [];
}
