import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _offlineAttendanceKey = 'offline_attendance_queue';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveOfflineAttendanceQueue(String jsonPayload) async {
    await _storage.write(key: _offlineAttendanceKey, value: jsonPayload);
  }

  static Future<String?> getOfflineAttendanceQueue() async {
    return await _storage.read(key: _offlineAttendanceKey);
  }

  static Future<void> clearOfflineAttendanceQueue() async {
    await _storage.delete(key: _offlineAttendanceKey);
  }
}
