import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart'; // ✅ Import ApiConfig
import '../models/travel_tour_model.dart';
import '../models/booking_model.dart';

class TourService {
  // ✅ SỬ DỤNG ApiConfig THAY VÌ HARDCODE
  static String get baseUrl => ApiConfig.apiUrl;

  // ========================================
  // HELPER: GET TOKEN
  // ========================================
  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ THỬ NHIỀU KEY (để tương thích với cả auth_service)
      String? token = prefs.getString('jwt_token');
      token ??= prefs.getString('auth_token');

      debugPrint('🔑 Getting token from storage...');
      debugPrint('🔍 Keys in storage: ${prefs.getKeys()}');

      if (token != null && token.isNotEmpty) {
        debugPrint('✅ Token found: ${token.substring(0, 20)}...');
        return token;
      } else {
        debugPrint('❌ No token found in storage');
        debugPrint('📋 Available keys: ${prefs.getKeys().join(", ")}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }

  // ========================================
  // HELPER: PARSE RESPONSE
  // ========================================
  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint(
          '📥 Response body: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

      // ✅ HANDLE EMPTY RESPONSE
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true, 'message': 'Success', 'data': null};
        } else {
          return {
            'success': false,
            'message':
                'Server returned empty response (HTTP ${response.statusCode})',
            'data': null
          };
        }
      }

      // ✅ TRY PARSE JSON
      final dynamic parsedBody = json.decode(response.body);

      // ✅ IF RESPONSE IS A LIST (e.g., GET /api/TravelTour)
      if (parsedBody is List) {
        return {
          'success': true,
          'message': 'Success',
          'data': parsedBody,
        };
      }

      // ✅ IF RESPONSE IS AN OBJECT
      final Map<String, dynamic> data = parsedBody as Map<String, dynamic>;

      // ✅ DETERMINE SUCCESS BASED ON STATUS CODE
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Success',
          'data': data['data'] ?? data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Unknown error',
          'data': null,
        };
      }
    } catch (e) {
      debugPrint('❌ Parse error: $e');
      debugPrint('❌ Raw response: ${response.body}');
      return {
        'success': false,
        'message': 'Lỗi parse dữ liệu: ${e.toString()}',
        'data': null,
      };
    }
  }

  // ========================================
  // 1. GET ALL TOURS
  // ========================================
  static Future<Map<String, dynamic>> getAllTours() async {
    try {
      final url = '$baseUrl/TravelTour';
      debugPrint('📥 Fetching all tours from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final parsed = _parseResponse(response);

      if (parsed['success'] == true && parsed['data'] != null) {
        // ✅ PARSE LIST OF TOURS
        final List<dynamic> toursList =
            parsed['data'] is List ? parsed['data'] : [];

        final List<TravelTour> tours =
            toursList.map((json) => TravelTour.fromJson(json)).toList();

        debugPrint('✅ Loaded ${tours.length} tours');

        return {'success': true, 'data': tours, 'message': 'Success'};
      } else {
        debugPrint('❌ Failed to load tours: ${parsed['message']}');
        return parsed;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Get tours error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
        'data': null
      };
    }
  }

  // ========================================
  // 2. GET MY BOOKINGS
  // ========================================
  static Future<Map<String, dynamic>> getMyBookings() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        debugPrint('❌ No token available for getMyBookings');
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập để xem lịch sử đặt tour',
          'data': null,
          'requireLogin': true,
        };
      }

      // ✅ SỬA: Đổi endpoint sang /my-bookings
      final url = '$baseUrl/Booking/my-bookings';

      debugPrint('📥 Fetching bookings from: $url');
      debugPrint('🔑 Using token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 Bookings response status: ${response.statusCode}');
      debugPrint('📥 Bookings response body: ${response.body}');

      // ✅ CHECK FOR 401 UNAUTHORIZED
      if (response.statusCode == 401) {
        debugPrint('❌ Token expired or invalid - clearing storage');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt_token');
        await prefs.remove('auth_token');

        return {
          'success': false,
          'message': 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại',
          'data': null,
          'requireLogin': true,
        };
      }

      final parsed = _parseResponse(response);

      if (parsed['success'] == true && parsed['data'] != null) {
        // ✅ PARSE LIST OF BOOKINGS
        final List<dynamic> bookingsList =
            parsed['data'] is List ? parsed['data'] : [];

        final List<Booking> bookings =
            bookingsList.map((json) => Booking.fromJson(json)).toList();

        debugPrint('✅ Loaded ${bookings.length} bookings');

        return {'success': true, 'data': bookings, 'message': 'Success'};
      } else {
        debugPrint('❌ Failed to load bookings: ${parsed['message']}');
        return parsed;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Get bookings error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
        'data': null
      };
    }
  }

  // ========================================
  // 3. CREATE BOOKING
  // ========================================
  static Future<Map<String, dynamic>> createBooking({
    required int tourId,
    required int numberOfPeople,
    required DateTime travelDate,
    String? specialRequests,
  }) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        debugPrint('❌ No token available for createBooking');
        debugPrint('📋 Please ensure user is logged in first');
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập để đặt tour',
          'data': null,
          'requireLogin': true, // ✅ Flag để UI biết cần login
        };
      }

      final url = '$baseUrl/Booking';
      debugPrint('📤 Creating booking for tour $tourId...');
      debugPrint('📤 POST $url');
      debugPrint('🔑 Using token: ${token.substring(0, 20)}...');

      final body = json.encode({
        'tourId': tourId,
        'numberOfPeople': numberOfPeople,
        'travelDate': travelDate.toIso8601String(),
        'specialRequests': specialRequests ?? '',
      });

      debugPrint('📤 Request body: $body');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📥 Create booking response status: ${response.statusCode}');
      debugPrint('📥 Create booking response body: ${response.body}');

      // ✅ CHECK FOR 401 UNAUTHORIZED
      if (response.statusCode == 401) {
        debugPrint('❌ Token expired or invalid - clearing storage');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt_token');
        await prefs.remove('auth_token');

        return {
          'success': false,
          'message': 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại',
          'data': null,
          'requireLogin': true,
        };
      }

      final parsed = _parseResponse(response);

      if (parsed['success'] == true) {
        debugPrint('✅ Booking created successfully');
      } else {
        debugPrint('❌ Booking failed: ${parsed['message']}');
      }

      return parsed;
    } catch (e, stackTrace) {
      debugPrint('❌ Create booking error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Lỗi đặt tour: ${e.toString()}',
        'data': null
      };
    }
  }

  // ========================================
  // 4. CANCEL BOOKING
  // ========================================
  static Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        debugPrint('❌ No token available for cancelBooking');
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập',
          'data': null,
          'requireLogin': true,
        };
      }

      final url = '$baseUrl/Booking/$bookingId/cancel';
      debugPrint('📤 Cancelling booking $bookingId...');
      debugPrint('🔑 Using token: ${token.substring(0, 20)}...');

      final response = await http
          .put(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        debugPrint('❌ Token expired or invalid');
        return {
          'success': false,
          'message': 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại',
          'data': null,
          'requireLogin': true,
        };
      }

      final parsed = _parseResponse(response);

      if (parsed['success'] == true) {
        debugPrint('✅ Booking cancelled successfully');
      } else {
        debugPrint('❌ Cancel failed: ${parsed['message']}');
      }

      return parsed;
    } catch (e, stackTrace) {
      debugPrint('❌ Cancel booking error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Lỗi hủy đơn: ${e.toString()}',
        'data': null
      };
    }
  }

  // ========================================
  // 5. TEST CONNECTION
  // ========================================
  static Future<bool> testConnection() async {
    try {
      final url = '$baseUrl/TravelTour';
      debugPrint('🔍 Testing connection to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      debugPrint('✅ Connection OK - Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Connection failed: $e');
      return false;
    }
  }

  // ========================================
  // 6. DEBUG: CHECK AUTH STATUS
  // ========================================
  static Future<Map<String, dynamic>> debugAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final token = await _getToken();

      final status = {
        'hasToken': token != null && token.isNotEmpty,
        'tokenPreview': token != null ? token.substring(0, 20) + '...' : null,
        'allStorageKeys': allKeys.toList(),
        'jwtToken': prefs.getString('jwt_token'),
        'authToken': prefs.getString('auth_token'),
        'userId': prefs.getInt('user_id'),
        'userEmail': prefs.getString('user_email'),
      };

      debugPrint('🔍 ════════ AUTH DEBUG INFO ════════');
      debugPrint('📋 Storage Keys: ${status['allStorageKeys']}');
      debugPrint('🔑 Has Token: ${status['hasToken']}');
      debugPrint('👤 User ID: ${status['userId']}');
      debugPrint('📧 Email: ${status['userEmail']}');
      debugPrint('════════════════════════════════════\n');

      return status;
    } catch (e) {
      debugPrint('❌ Debug auth status error: $e');
      return {'error': e.toString()};
    }
  }
}
