// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  // ✅ Dùng config chung
  static String get baseUrl => ApiConfig.authUrl;

  // ✅ Login với named parameters
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔧 Logging in: $email');

      final response = await http.post(
        Uri.parse('${ApiConfig.authUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('🔧 Login response status: ${response.statusCode}');
      print('🔧 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Backend trả về: { success: true, data: { token: "...", user: {...} } }
        // ✅ Lưu token và user
        final prefs = await SharedPreferences.getInstance();

        if (data['data']['token'] != null) {
          await prefs.setString('token', data['data']['token']);
          await prefs.setString('jwt_token', data['data']['token']);
          print('✅ Token saved: ${data['data']['token'].substring(0, 20)}...');
        }

        if (data['data']['user'] != null) {
          final userJson = jsonEncode(data['data']['user']);
          await prefs.setString('user', userJson);
          print('✅ User saved: ${data['data']['user']['email']}');
        }

        return {
          'success': true,
          'message': 'Đăng nhập thành công',
          'data': data['data'], // ✅ Trả về data object
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Đăng nhập thất bại',
        };
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
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

  // ✅ THÊM: Get current user from SharedPreferences
  static Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson != null && userJson.isNotEmpty) {
        final userData = jsonDecode(userJson);
        return UserModel.fromJson(userData);
      }

      print('⚠️ No user found in SharedPreferences');
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  // ✅ THÊM: Get token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  // ✅ THÊM: Check if logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ✅ THÊM: Logout
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('token');
      await prefs.remove('user');
      print('✅ Logged out successfully');
    } catch (e) {
      print('❌ Error logging out: $e');
    }
  }
}
