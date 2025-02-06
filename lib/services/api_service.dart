import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/case_list.dart';
import '../utils/constants.dart';

class ApiService {
  // General method to send requests
  static Future<Map<String, dynamic>> _sendRequest(
      String endpoint, Map<String, dynamic> bodyData) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(baseUrl + endpoint),
      );
      request.fields.addAll({'data': jsonEncode(bodyData)});

      http.StreamedResponse streamedResponse =
          await request.send().timeout(const Duration(seconds: 10));

      String responseBody = await streamedResponse.stream.bytesToString();
      print('Raw API Response: $responseBody'); // Debugging

      if (streamedResponse.statusCode == 200) {
        var decodedResponse = jsonDecode(responseBody);

        return {
          'success': decodedResponse['success'] ?? false,
          'data': decodedResponse['data'] ?? {},
          'message': decodedResponse['message'] ?? 'No message',
          'error': decodedResponse['error'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${streamedResponse.reasonPhrase}',
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Error occurred: $error'};
    }
  }

  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    return _sendRequest(
      '/login_intern',
      {
        'user_id': email,
        'password': password,
      },
    );
  }
}

class CaseApiService {
  static Future<List<CaseListData>> fetchCaseList(String intern_id) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/intern_case_history'),
    );

    request.fields['intern_id'] = intern_id;

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseData = json.decode(await response.stream.bytesToString());
      if (responseData['success']) {
        // print("Response Data: ${responseData['data']}");
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
