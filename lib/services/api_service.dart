import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/storage.dart';
import 'download_service.dart';

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

  static String _messageFromResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final detail = decoded['detail'];

        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }

        if (detail is List && detail.isNotEmpty) {
          final messages = detail.map((item) {
            if (item is Map) {
              final location = item['loc'];
              final msg = item['msg']?.toString() ?? 'Valor inválido';
              if (location is List && location.isNotEmpty) {
                final field = location.last.toString().replaceAll('_', ' ');
                return '$field: $msg';
              }
              return msg;
            }
            return item.toString();
          }).join('\n');
          return messages;
        }

        final message = decoded['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }
      }

      return 'Erro do servidor (${response.statusCode})';
    } catch (_) {
      return response.body.isNotEmpty
          ? response.body
          : 'Erro do servidor (${response.statusCode})';
    }
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
        throw ApiException('Sessão expirada. Inicie sessão novamente.');
      }
      throw ApiException(_messageFromResponse(response));
    } on TimeoutException {
      throw ApiException('O servidor não está a responder. O backend está ativo?');
    } on http.ClientException {
      throw ApiException('Não foi possível contactar o servidor. Verifique a ligação.');
    }
  }

  static Future<Map<String, dynamic>> _getMap(String path) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}$path'), headers: headers)
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException(_messageFromResponse(response));
    } on TimeoutException {
      throw ApiException('O servidor não está a responder. O backend está ativo?');
    }
  }

  static Future<List<dynamic>> getListByPath(String path) => _getList(path);
  static Future<Map<String, dynamic>> getMapByPath(String path) => _getMap(path);

  static Future<Map<String, dynamic>> createRecord(String path, Map<String, dynamic> payload) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(Uri.parse('${ApiConstants.baseUrl}$path'), headers: headers, body: jsonEncode(payload))
          .timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException(_messageFromResponse(response));
    } on TimeoutException {
      throw ApiException('O servidor não está a responder. O backend está ativo?');
    }
  }

  static Future<Map<String, dynamic>> updateRecord(String path, dynamic id, Map<String, dynamic> payload) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .put(Uri.parse('${ApiConstants.baseUrl}$path/$id'), headers: headers, body: jsonEncode(payload))
          .timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException(_messageFromResponse(response));
    } on TimeoutException {
      throw ApiException('O servidor não está a responder. O backend está ativo?');
    }
  }

  static Future<void> deleteRecord(String path, dynamic id) async => deleteByPath('$path/$id');

  static Future<void> deleteByPath(String path) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(Uri.parse('${ApiConstants.baseUrl}$path'), headers: headers)
          .timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
      throw ApiException(_messageFromResponse(response));
    } on TimeoutException {
      throw ApiException('O servidor não está a responder. O backend está ativo?');
    }
  }

  static Future<List<dynamic>> getStudents() => _getList('/students');
  static Future<List<dynamic>> getProfessors() => _getList('/professors');
  static Future<List<dynamic>> getRooms() => _getList('/rooms');
  static Future<List<dynamic>> getDisciplines() => _getList('/disciplines');
  static Future<List<dynamic>> getClasses() => _getList('/classes');
  static Future<List<dynamic>> getCourses() => _getList('/courses');
  static Future<List<dynamic>> getUsers() => _getList('/users');
  static Future<List<dynamic>> getAttendance({
    String? startDate,
    String? endDate,
    int? classId,
    int? studentId,
    int? disciplineId,
    String? punchType,
    String? punchMethod,
    bool? isSynced,
    int limit = 300,
  }) {
    final query = <String, String>{
      'limit': limit.toString(),
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (classId != null) 'class_id': classId.toString(),
      if (studentId != null) 'student_id': studentId.toString(),
      if (disciplineId != null) 'discipline_id': disciplineId.toString(),
      if (punchType != null) 'punch_type': punchType,
      if (punchMethod != null) 'punch_method': punchMethod,
      if (isSynced != null) 'is_synced': isSynced.toString(),
    };
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    return _getList('/attendance$suffix');
  }
  static Future<List<dynamic>> getJustifications() => _getList('/attendance-justifications');


  static Future<Map<String, dynamic>> punchAttendance({
    required String cardUid,
    String punchMethod = 'nfc',
    String? punchType,
    String? punchTime,
    bool isSynced = true,
  }) async {
    try {
      final headers = await _authHeaders();
      final payload = <String, dynamic>{
        'card_uid': cardUid,
        'punch_method': punchMethod,
        'is_synced': isSynced,
      };
      if (punchType != null) payload['punch_type'] = punchType;
      if (punchTime != null) payload['punch_time'] = punchTime;

      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/attendance/punch'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException(_messageFromResponse(response));
    } on TimeoutException {
      throw ApiException('O servidor não está a responder. A picagem pode ser guardada offline.');
    } on http.ClientException {
      throw ApiException('Não foi possível contactar o servidor. A picagem pode ser guardada offline.');
    }
  }

  static Future<Map<String, dynamic>> syncOfflineAttendance(List<Map<String, dynamic>> records) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/attendance/offline-sync'),
            headers: headers,
            body: jsonEncode({'records': records}),
          )
          .timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException(_messageFromResponse(response));
    } on TimeoutException {
      throw ApiException('A sincronização demorou demasiado.');
    }
  }

  static Future<Map<String, dynamic>> getAttendanceDashboard({
    String? date,
    int? classId,
    int? disciplineId,
  }) async {
    final query = <String, String>{
      if (date != null) 'target_date': date,
      if (classId != null) 'class_id': classId.toString(),
      if (disciplineId != null) 'discipline_id': disciplineId.toString(),
    };
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    return _getMap('/attendance/dashboard$suffix');
  }

  static Future<Map<String, dynamic>> getAttendanceAlerts({
    String? date,
    int? classId,
    int? disciplineId,
    int days = 7,
  }) async {
    final query = <String, String>{
      'days': days.toString(),
      if (date != null) 'target_date': date,
      if (classId != null) 'class_id': classId.toString(),
      if (disciplineId != null) 'discipline_id': disciplineId.toString(),
    };
    final suffix = '?${Uri(queryParameters: query).query}';
    return _getMap('/attendance/alerts$suffix');
  }
  static Future<List<dynamic>> getPendingScheduleApprovals() =>
      _getList('/schedule/pending-approval');

  static Future<List<dynamic>> getScheduleApprovalDetails({
    required int classId,
    required String startDate,
    required String endDate,
  }) =>
      _getList('/schedule/approval-details/$classId?start_date=$startDate&end_date=$endDate');

  static Future<Map<String, dynamic>> approveScheduleBatch({
    required int classId,
    required String startDate,
    required String endDate,
  }) async {
    return createRecord('/schedule/approve-batch', {
      'class_id': classId,
      'start_date': startDate,
      'end_date': endDate,
    });
  }

  static Future<Map<String, dynamic>> rejectScheduleBatch({
    required int classId,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    return createRecord('/schedule/reject-batch', {
      'class_id': classId,
      'start_date': startDate,
      'end_date': endDate,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }



  static String _filenameFromHeaders(Map<String, String> headers, String fallback) {
    final contentDisposition = headers['content-disposition'];
    if (contentDisposition == null) return fallback;

    final match = RegExp(r'filename="?([^";]+)"?').firstMatch(contentDisposition);
    return match?.group(1) ?? fallback;
  }

  static Future<void> downloadScheduleExport({
    required int classId,
    required String format,
    String status = 'all',
  }) async {
    if (format != 'pdf' && format != 'excel') {
      throw ApiException('Formato de exportação inválido.');
    }

    try {
      final headers = await _authHeaders();
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/schedule/export/$format?class_id=$classId&status=$status'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final extension = format == 'pdf' ? 'pdf' : 'xlsx';
        final contentType = format == 'pdf'
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        final filename = _filenameFromHeaders(
          response.headers,
          'academia360_horario.$extension',
        );
        DownloadService.downloadBytes(
          Uint8List.fromList(response.bodyBytes),
          filename: filename,
          contentType: contentType,
        );
        return;
      }

      throw ApiException(_messageFromResponse(response));
    } on TimeoutException {
      throw ApiException('A exportação demorou demasiado.');
    } on http.ClientException {
      throw ApiException('Não foi possível contactar o servidor para exportar o horário.');
    }
  }

  static Future<List<dynamic>> getScheduleByClass(int classId) =>
      _getList('/schedule/class/$classId');

  static Future<Map<String, dynamic>> getScheduleReadiness({
    required int classId,
    required String startDate,
    required String endDate,
  }) async {
    return _getMap('/schedule/generation-readiness/$classId?start_date=$startDate&end_date=$endDate');
  }

  static Future<Map<String, dynamic>> generateSchedule({
    required int classId,
    required String startDate,
    required String endDate,
    String schoolStart = '09:00:00',
    String schoolEnd = '17:00:00',
    bool replaceExisting = false,
    bool dryRun = true,
    String status = 'draft',
    int? maxSessionsPerDiscipline = 1,
    int maxTotalSessions = 300,
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
              'school_start': schoolStart,
              'school_end': schoolEnd,
              'replace_existing': replaceExisting,
              'dry_run': dryRun,
              'status': status,
              'max_sessions_per_discipline': maxSessionsPerDiscipline,
              'max_total_sessions': maxTotalSessions,
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException(_messageFromResponse(response));
    } on TimeoutException {
      throw ApiException('A geração demorou demasiado. Experimente um intervalo de datas mais curto.');
    }
  }
}
