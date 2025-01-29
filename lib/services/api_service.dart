import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/case_list.dart';
import '../utils/constants.dart';

class ApiService {
  static const Map<String, String> headers = {
    'User-Agent': 'Apidog/1.0.0 (https://apidog.com)',
  };

  // General method to send requests
  static Future<Map<String, dynamic>> _sendRequest(
      String endpoint, Map<String, dynamic> bodyData) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(baseUrl + endpoint),
      );
      request.fields.addAll({'data': jsonEncode(bodyData)});
      request.headers.addAll(headers);

      // Send the request and handle timeout
      http.StreamedResponse response =
          await request.send().timeout(const Duration(seconds: 10));

      // Handle response status
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody);

        if (decodedResponse['success'] == true) {
          return {
            'success': true,
            'data': decodedResponse['data'],
            'message': decodedResponse['message'],
            'error': decodedResponse['error'] ?? '',
          };
        } else {
          return {
            'success': false,
            'message': decodedResponse['message'] ?? 'Operation failed',
            'error': decodedResponse['error'] ?? '',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.reasonPhrase}',
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
        print("Response Data: ${responseData['data']}");
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
