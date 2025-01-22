import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/case_list.dart';

class CaseApiService {
  static const String baseUrl =
      'https://pragmanxt.com/case_sync/services/admin/v1/index.php';

  static Future<List<CaseListData>> fetchCaseList() async {
    final response = await http.get(Uri.parse('$baseUrl/get_case_history'));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        final List<dynamic> data = responseData['data'];
        return data.map((item) => CaseListData.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to fetch case list: ${responseData['message']}');
      }
    } else {
      throw Exception(
          'Failed to fetch case list. Status code: ${response.statusCode}');
    }
  }
}
