import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/storage.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const _timeout = Duration(seconds: 15);

  static Future<Map<String, String>> _authHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<List<dynamic>> _getList(String path) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}$path'), headers: headers)
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      if (response.statusCode == 401) {
        throw ApiException('Session expired. Please sign in again.');
      }
      throw ApiException('Server error (${response.statusCode})');
    } on TimeoutException {
      throw ApiException('Server is not responding. Is the backend running?');
    } on http.ClientException {
      throw ApiException('Cannot reach the server. Check your connection.');
    }
  }

  static Future<List<dynamic>> getStudents() => _getList('/students');
  static Future<List<dynamic>> getProfessors() => _getList('/professors');
  static Future<List<dynamic>> getRooms() => _getList('/rooms');
  static Future<List<dynamic>> getDisciplines() => _getList('/disciplines');
  static Future<List<dynamic>> getClasses() => _getList('/classes');
  static Future<List<dynamic>> getCourses() => _getList('/courses');
  static Future<List<dynamic>> getUsers() => _getList('/users');
  static Future<List<dynamic>> getAttendance() => _getList('/attendance');
  static Future<List<dynamic>> getScheduleByClass(int classId) =>
      _getList('/schedule/class/$classId');

  static Future<Map<String, dynamic>> generateSchedule({
    required int classId,
    required String startDate,
    required String endDate,
    bool replaceExisting = false,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/schedule/generate'),
            headers: headers,
            body: jsonEncode({
              'class_id': classId,
              'start_date': startDate,
              'end_date': endDate,
              'replace_existing': replaceExisting,
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      final detail = jsonDecode(response.body)['detail'];
      throw ApiException(detail?.toString() ?? 'Generation failed');
    } on TimeoutException {
      throw ApiException('Generation timed out. Try a shorter date range.');
    }
  }
}
