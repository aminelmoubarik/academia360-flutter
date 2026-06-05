import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/storage.dart';
import '../models/user.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await SecureStorage.saveToken(data['access_token']);
      return true;
    }

    return false;
  }

  static Future<User?> getCurrentUser() async {
    final token = await SecureStorage.getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }

    return null;
  }

  static Future<void> logout() async {
    await SecureStorage.deleteToken();
  }
}