import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiResponse {
  // Async login method
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    try {
      var headers = {
        'User-Agent': 'Apidog/1.0.0 (https://apidog.com)',
      };
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://pragmanxt.com/case_sync/services/intern/v1/index.php/login_intern'),
      );

      // Add fields to the request
      request.fields.addAll({
        'data': jsonEncode({
          'user_id': email,
          'password': password,
        })
      });

      request.headers.addAll(headers);

      // Send the request and wait for the response asynchronously
      http.StreamedResponse response =
          await request.send().timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody);

        if (decodedResponse['success'] == true) {
          return {
            'success': true,
            'data': decodedResponse['data'],
            'message': decodedResponse['message']
          };
        } else {
          return {
            'success': false,
            'message': decodedResponse['message'] ?? 'Login failed'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.reasonPhrase}'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Error occurred: $error'};
    }
  }

  // Async advocate registration method
  static Future<Map<String, dynamic>> registerAdvocate(
      String name, String contact, String email, String password) async {
    try {
      var headers = {
        'User-Agent': 'Apidog/1.0.0 (https://apidog.com)',
      };
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://pragmanxt.com/case_sync/services/intern/v1/index.php/login_intern'),
      );

      // Add fields to the request
      request.fields.addAll({
        'data': jsonEncode({
          'name': name,
          'contact': contact,
          'email': email,
          'password': password,
        })
      });

      request.headers.addAll(headers);

      // Send the request and wait for the response asynchronously
      http.StreamedResponse response =
          await request.send().timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody);

        if (decodedResponse['success'] == true) {
          return {
            'success': true,
            'message': decodedResponse['message'],
            'data': decodedResponse['data'],
          };
        } else {
          return {
            'success': false,
            'message': decodedResponse['message'] ?? 'Registration failed'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.reasonPhrase}'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Error occurred: $error'};
    }
  }
}
