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

  static Future<List<dynamic>> _getList(String path) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load $path (${response.statusCode})');
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
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['detail'] ?? 'Generation failed');
  }
}
