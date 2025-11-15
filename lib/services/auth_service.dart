// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:5000/api/auth';

  // ✅ Login với named parameters
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Logging in: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // ✅ Kiểm tra 2 trường hợp cấu trúc response

        // Trường hợp 1: Response có nested "data"
        String? token;
        Map<String, dynamic>? userData;

        if (data['data'] != null) {
          // Response: { "data": { "token": "...", "user": {...} } }
          token = data['data']['token'];
          userData = data['data']['user'];
        } else if (data['token'] != null) {
          // Response: { "token": "...", "user": {...} }
          token = data['token'];
          userData = data['user'];
        } else {
          debugPrint('❌ Invalid response structure');
          return {'success': false, 'message': 'Invalid response structure'};
        }

        if (token == null || userData == null) {
          return {'success': false, 'message': 'Token or user data not found'};
        }

        // Lưu vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setInt('user_id', userData['id']);
        await prefs.setString('user_username',
            userData['fullName'] ?? userData['email'].split('@')[0]);
        await prefs.setString('user_email', userData['email']);

        return {
          'success': true,
          'data': {
            'token': token,
            'user': userData,
          }
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng nhập thất bại'
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Login error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // ✅ Register với named parameters
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      debugPrint('📝 Registering: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
        }),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Xử lý 2 trường hợp cấu trúc
        String? token;
        Map<String, dynamic>? userData;

        if (data['data'] != null) {
          token = data['data']['token'];
          userData = data['data']['user'];
        } else if (data['token'] != null) {
          token = data['token'];
          userData = data['user'];
        } else {
          // Nếu không có token (chỉ thông báo thành công)
          return {
            'success': true,
            'message': data['message'] ?? 'Đăng ký thành công'
          };
        }

        if (token != null && userData != null) {
          // Lưu vào SharedPreferences nếu có token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setInt('user_id', userData['id']);
          await prefs.setString('user_username',
              userData['fullName'] ?? userData['email'].split('@')[0]);
          await prefs.setString('user_email', userData['email']);

          return {
            'success': true,
            'data': {
              'token': token,
              'user': userData,
            }
          };
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Đăng ký thành công'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng ký thất bại'
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Register error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  // ✅ Get current user
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final username = prefs.getString('user_username');
    final email = prefs.getString('user_email');

    if (userId != null && email != null) {
      return {
        'id': userId,
        'username': username ?? 'User',
        'email': email,
      };
    }
    return null;
  }
}
