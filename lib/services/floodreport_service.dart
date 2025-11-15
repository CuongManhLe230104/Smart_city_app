import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FloodReportService {
  static const String baseUrl = 'http://10.0.2.2:5000/api/floodreports';

  // ✅ Lấy TẤT CẢ báo cáo (không chỉ approved)
  static Future<Map<String, dynamic>> getAllReports({
    String? status,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      String url = '$baseUrl/admin/all?page=$page&pageSize=$pageSize';
      if (status != null && status.isNotEmpty && status != 'all') {
        url += '&status=$status';
      }

      debugPrint('📥 Fetching reports from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ✅ Lấy chỉ báo cáo đã duyệt (cho map)
  static Future<Map<String, dynamic>> getApprovedReports() async {
    try {
      debugPrint('📥 Fetching approved reports...');

      final response = await http.get(
        Uri.parse('$baseUrl/approved'),
        headers: {'Accept': 'application/json'},
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ✅ Lấy báo cáo của user
  static Future<Map<String, dynamic>> getMyReports(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-reports/$userId'),
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

  // ✅ Tạo báo cáo mới
  static Future<Map<String, dynamic>> createFloodReport({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    required String imageUrl,
    required String waterLevel,
    required int userId,
  }) async {
    try {
      debugPrint('📤 Creating flood report...');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'imageUrl': imageUrl,
          'waterLevel': waterLevel,
          'userId': userId,
        }),
      );

      debugPrint('📥 Response: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }
}
