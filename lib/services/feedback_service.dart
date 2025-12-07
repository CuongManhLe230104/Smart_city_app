import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class FeedbackService {
  // ✅ SỬA: Dùng ApiConfig
  static String get baseUrl => '${ApiConfig.apiUrl}/feedback';

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
      final url = baseUrl; // POST /api/feedback
      debugPrint('📤 Sending feedback to: $url');
      debugPrint(
          '📦 Data: {title: $title, category: $category, userId: $userId}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
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

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        final data = json.decode(response.body);
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

  // ✅ Lấy phản ánh công khai
  static Future<Map<String, dynamic>> getPublicFeedbacks({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? status,
  }) async {
    try {
      // Build URL với query params
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (category != null && category != 'Tất cả') {
        queryParams['category'] = category;
      }

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri =
          Uri.parse('$baseUrl/public').replace(queryParameters: queryParams);

      debugPrint('📤 Fetching public feedbacks: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        // ✅ KIỂM TRA: Response có rỗng không
        if (response.body.isEmpty) {
          debugPrint('⚠️ Empty response body');
          return {
            'success': true,
            'data': [],
            'pagination': {
              'page': page,
              'pageSize': pageSize,
              'totalCount': 0,
              'totalPages': 0,
            }
          };
        }

        final data = json.decode(response.body);

        return {
          'success': true,
          'data': data['data'] ?? [],
          'pagination': data['pagination'] ??
              {
                'page': page,
                'pageSize': pageSize,
                'totalCount': 0,
                'totalPages': 0,
              },
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi tải dữ liệu'
        };
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ✅ Lấy phản ánh của user
  static Future<Map<String, dynamic>> getMyFeedbacks(int userId) async {
    try {
      final url = '$baseUrl/my-feedbacks/$userId';
      debugPrint('📤 Fetching my feedbacks: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {'success': true, 'data': []};
        }

        final data = json.decode(response.body);
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi tải dữ liệu'
        };
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // Upload và lưu hình ảnh phản ánh
  static Future<String?> uploadFeedbackImage(String filePath) async {
    try {
      final url = '${ApiConfig.apiUrl}/upload'; // Đường dẫn đến API upload
      debugPrint('📤 Uploading image to: $url');

      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['type'] = 'feedback' // Thêm trường type = feedback
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();

      debugPrint('📥 Upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        return jsonResponse['url']; // Trả về URL hình ảnh đã tải lên
      } else {
        debugPrint('❌ Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  // Chuyển đổi đường dẫn tương đối thành đường dẫn đầy đủ để hiển thị
  static String toFullUrl(String relativePath) {
    return '${ApiConfig.apiUrl}$relativePath';
  }

  // Lấy đường dẫn tương đối từ URL đầy đủ
  static String toRelativePath(String fullUrl) {
    final uri = Uri.parse(fullUrl);
    return uri.path; // Trả về phần đường dẫn của URL
  }
}
