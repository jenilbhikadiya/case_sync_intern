import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/case_list.dart';

class CaseApiService {
  static const String baseUrl =
      'https://pragmanxt.com/case_sync/services/intern/v1/index.php';

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

class ApiService {
  static const String baseUrl =
      'https://pragmanxt.com/case_sync_pro/services/intern/v1/index.php/';
  // General method to send requests
  static Future<Map<String, dynamic>> _sendLoginRequest(
      Map<String, dynamic> bodyData) async {
    try {
      var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              'https://pragmanxt.com/case_sync_pro/services/intern/v1/index.php/login_intern'));

      request.fields.addAll({'data': jsonEncode(bodyData)});

      // Send the request and handle timeout
      print("Sending request!!!!!!!!!!!!!!!!!!!!!!!!!!");
      http.StreamedResponse response =
          await request.send().timeout(const Duration(seconds: 10));

      // Handle response status
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody);

        print("Response received: ${decodedResponse['data'][0]}");

        if (decodedResponse['success'] == true) {
          return {
            'success': true,
            'data': decodedResponse['data'][0],
            'message': decodedResponse['message'],
          };
        } else if (decodedResponse['success'] == false) {
          return {
            'success': false,
            'message': decodedResponse['message'],
          };
        } else {
          return {
            'success': false,
            'message': decodedResponse['message'] ?? 'Operation failed',
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

  // Login user method
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    var response = await _sendLoginRequest(
      {
        'user_id': email,
        'password': password,
      },
    );
    print("Response: $response");
    return response;
  }
}
