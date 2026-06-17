import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/storage.dart';
import '../models/user.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/auth/login');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,
          'password': password,
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await SecureStorage.saveToken(data['access_token']);
        return true;
      }

      return false;
    } on TimeoutException {
      throw Exception('Tempo de espera excedido. O servidor pode ainda estar a iniciar.');
    } catch (e) {
      throw Exception('Não foi possível ligar à API: $e');
    }
  }

  static Future<User?> getCurrentUser() async {
    final token = await SecureStorage.getToken();
    if (token == null) return null;

    final uri = Uri.parse('${ApiConstants.baseUrl}/auth/me');

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }

      await SecureStorage.deleteToken();
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> logout() async {
    await SecureStorage.deleteToken();
  }
}