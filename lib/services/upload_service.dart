import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

class UploadService {
  static const String baseUrl = 'http://10.0.2.2:5000/api/upload';

  // 📤 Upload ảnh
  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      debugPrint('Uploading image: ${imageFile.path}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/image'),
      );

      // Thêm file vào request
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      // Gửi request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'url': data['url'],
          'fileName': data['fileName']
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Upload thất bại'
        };
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return {'success': false, 'message': 'Lỗi upload: $e'};
    }
  }

  static Future<bool> deleteImage(String fileName) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/image/$fileName'),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }
}
