import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/storage.dart';

class ApiService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<List<dynamic>> getStudents() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/students'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load students');
  }

  static Future<List<dynamic>> getClasses() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/classes'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load classes');
  }

  static Future<List<dynamic>> getScheduleByClass(int classId) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/schedule/class/$classId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load schedule');
  }

  static Future<Map<String, dynamic>> generateSchedule({
    required int classId,
    required String startDate,
    required String endDate,
    bool replaceExisting = false,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/schedule/generate'),
      headers: headers,
      body: jsonEncode({
        'class_id': classId,
        'start_date': startDate,
        'end_date': endDate,
        'replace_existing': replaceExisting,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(jsonDecode(response.body)['detail'] ?? 'Generation failed');
  }
}
