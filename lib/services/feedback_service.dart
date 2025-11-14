import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FeedbackService {
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android Emulator

  // Gửi phản ánh mới
  static Future<Map<String, dynamic>> createFeedback({
    required String title,
    required String description,
    required String category,
    required int userId,
    String? location,
    String? imageUrl,
  }) async {
    try {
      debugPrint('📤 Sending feedback...');

      final response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'category': category,
          'location': location,
          'imageUrl': imageUrl,
          'userId': userId,
        }),
      );

      debugPrint('📥 Response: ${response.statusCode}');
      debugPrint('📥 Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gửi phản ánh thất bại'
        };
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Thêm method mới - Lấy tất cả phản ánh công khai
  static Future<Map<String, dynamic>> getPublicFeedbacks({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? status,
  }) async {
    try {
      var uri =
          Uri.parse('$baseUrl/feedback/public?page=$page&pageSize=$pageSize');

      if (category != null && category.isNotEmpty) {
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          'category': category,
        });
      }

      if (status != null && status.isNotEmpty) {
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          'status': status,
        });
      }

      debugPrint('📤 Fetching public feedbacks: $uri');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      debugPrint('📥 Response: ${response.statusCode}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'pagination': data['pagination'],
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // Lấy phản ánh của user (giữ nguyên cho trang cá nhân)
  static Future<Map<String, dynamic>> getMyFeedbacks(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/feedback/my-feedbacks/$userId'),
        headers: {'Accept': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }
}
