import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class UploadService {
  // ✅ Upload feedback image
  static Future<String> uploadFeedbackImage(File imageFile) async {
    try {
      print('📤 Uploading feedback image: ${imageFile.path}');

      final uploadUrl = '${ApiConfig.baseUrl}/api/Upload/feedback';
      print('🔗 Upload URL: $uploadUrl');

      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);

        print('📦 Response data: $jsonData');

        if (jsonData['url'] != null) {
          final relativeUrl =
              jsonData['url'] as String; // /uploads/feedback-images/abc.jpg

          // ✅ TẠO FULL URL với base URL hiện tại
          final fullUrl = relativeUrl.startsWith('http')
              ? relativeUrl
              : '${ApiConfig.baseUrl}$relativeUrl';

          print('✅ Full image URL: $fullUrl');

          // ✅ TRẢ VỀ FULL URL (không lưu vào DB, chỉ dùng tạm)
          return fullUrl;
        } else {
          throw Exception('URL không hợp lệ trong response');
        }
      } else {
        var responseData = await response.stream.bytesToString();
        print('❌ Error response: $responseData');
        throw Exception('Upload thất bại: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Upload error: $e');
      rethrow;
    }
  }

  // ✅ Tương tự cho các methods khác
  static Future<String> uploadFloodImage(File imageFile) async {
    try {
      final uploadUrl = '${ApiConfig.baseUrl}/api/Upload/image';
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);

        final relativeUrl = jsonData['url'] as String;
        final fullUrl = relativeUrl.startsWith('http')
            ? relativeUrl
            : '${ApiConfig.baseUrl}$relativeUrl';

        return fullUrl;
      } else {
        throw Exception('Upload thất bại');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> uploadEventBanner(File imageFile) async {
    try {
      final uploadUrl = '${ApiConfig.baseUrl}/api/Upload/event-banner';
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);

        final relativeUrl = jsonData['url'] as String;
        final fullUrl = relativeUrl.startsWith('http')
            ? relativeUrl
            : '${ApiConfig.baseUrl}$relativeUrl';

        return fullUrl;
      } else {
        throw Exception('Upload thất bại');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ✅ Helper: Extract relative path from full URL
  static String toRelativePath(String fullUrl) {
    if (!fullUrl.startsWith('http')) {
      return fullUrl; // Đã là relative path
    }

    final uri = Uri.parse(fullUrl);
    return uri.path; // /uploads/feedback-images/abc.jpg
  }

  // ✅ Helper: Convert relative to full URL
  static String toFullUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    if (url.startsWith('http')) {
      return url; // Đã là full URL
    }

    return '${ApiConfig.baseUrl}$url';
  }
}
