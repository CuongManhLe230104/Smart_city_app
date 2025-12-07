import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/bus_route_model.dart';
import '../models/location_search_result.dart';
import '../models/event_banner_model.dart';
import '../config/api_config.dart';

class ApiService {
  static const String _myApiBaseUrl = 'http://10.0.2.2:5000';
  // --- 1. API THỜI TIẾT (giữ nguyên) ---
  Future<String> fetchWeather() async {
    if (ApiConfig.weatherApiKey == 'YOUR_API_KEY_HERE') {
      return 'Lỗi: Chưa có API Key';
    }
    try {
      const String lat = '10.4113';
      const String lon = '107.1362';
      final Uri url = Uri.parse(
        '${ApiConfig.weatherBaseUrl}/weather?lat=$lat&lon=$lon&appid=${ApiConfig.weatherApiKey}&units=metric&lang=vi',
      );
      final http.Response response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        String description = data['weather'][0]['description'];
        String temp = data['main']['temp'].toStringAsFixed(1);
        return "$temp°C - $description";
      } else {
        return 'Lỗi: ${response.statusCode}';
      }
    } catch (e) {
      return 'Lỗi kết nối';
    }
  }

  // --- 2. API BẢN ĐỒ (giữ nguyên) ---
  Future<Map<String, double>> fetchMapCoordinates() async {
    try {
      const String query = 'Vung Tau, Ba Ria - Vung Tau, Vietnam';
      final Uri url = Uri.parse(
        '${ApiConfig.mapBaseUrl}/search?key=${ApiConfig.mapApiKey}&q=$query&format=json',
      );
      final http.Response response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final Map<String, dynamic> firstResult = data[0];
          final double lat = double.parse(firstResult['lat']);
          final double lon = double.parse(firstResult['lon']);
          return {'lat': lat, 'lon': lon};
        } else {
          throw Exception('Không tìm thấy kết quả cho Vũng Tàu.');
        }
      } else {
        throw Exception('Lỗi API LocationIQ: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // --- 3. API BACKEND (✅ SỬA) ---
  Future<List<BusRouteModel>> fetchBusRoutes() async {
    final Uri url = Uri.parse(ApiConfig.busRoutesUrl); // ✅ SỬA
    final http.Response response;

    try {
      response = await http.get(url);
    } catch (e) {
      throw Exception(
        'Lỗi kết nối: Không thể kết nối tới backend. Backend đã chạy chưa?',
      );
    }

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonData = jsonDecode(responseBody);
      return jsonData.map((json) => BusRouteModel.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi khi tải tuyến xe buýt: ${response.statusCode}');
    }
  }

  Future<List<LocationSearchResult>> searchLocations(String query) async {
    final Uri url = Uri.parse(ApiConfig.searchUrl) // ✅ SỬA
        .replace(queryParameters: {'q': query});

    final http.Response response;

    try {
      response = await http.get(url);
    } catch (e) {
      throw Exception(
        'Lỗi kết nối: Không thể kết nối tới backend. Backend đã chạy chưa?',
      );
    }

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonData = jsonDecode(responseBody);
      return jsonData
          .map((json) => LocationSearchResult.fromJson(json))
          .toList();
    } else {
      throw Exception('Lỗi server (Search): ${response.statusCode}');
    }
  }

  Future<List<EventBannerModel>> fetchEventBanners() async {
    try {
      // ✅ ĐÚNG ENDPOINT
      final url = '${ApiConfig.apiUrl}/EventBanners';
      print('🔄 Fetching event banners from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        // ✅ Check empty response
        if (response.body.isEmpty) {
          print('⚠️ Empty response body');
          return [];
        }

        final List<dynamic> data = json.decode(response.body);
        print('📊 Parsed ${data.length} banners');

        // ✅ Parse banners
        final banners = data.map((json) {
          final banner = EventBannerModel.fromJson(json);
          print('🖼️ Banner ${banner.id}: ${banner.imageUrl}');
          return banner;
        }).toList();

        print('✅ Loaded ${banners.length} banners');
        return banners;
      } else {
        print('❌ Error status: ${response.statusCode}');
        throw Exception('Failed to load banners: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching banners: $e');
      print('❌ Stack trace: $stackTrace');
      return []; // Return empty list instead of throwing
    }
  }

  Future<List<BusRouteModel>> searchBusRoutes(String query) async {
    final Uri url = Uri.parse('${ApiConfig.busRoutesUrl}/search') // ✅ SỬA
        .replace(queryParameters: {'q': query});

    final http.Response response;

    try {
      response = await http.get(url);
    } catch (e) {
      throw Exception('Lỗi kết nối: Không thể kết nối tới backend.');
    }

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonData = jsonDecode(responseBody);
      return jsonData.map((json) => BusRouteModel.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi khi tìm kiếm tuyến xe buýt: ${response.statusCode}');
    }
  }

  Future<BusRouteModel> getBusRouteDetail(int id) async {
    final Uri url = Uri.parse('${ApiConfig.busRoutesUrl}/$id'); // ✅ SỬA
    final http.Response response;

    try {
      response = await http.get(url);
    } catch (e) {
      throw Exception('Lỗi kết nối: Không thể kết nối tới backend.');
    }

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonData = jsonDecode(responseBody);
      return BusRouteModel.fromJson(jsonData);
    } else {
      throw Exception('Lỗi khi tải chi tiết tuyến: ${response.statusCode}');
    }
  }

  Future<Map<String, String>> _getAuthHeaders({bool jsonType = true}) async {
    // TODO: 1. Lấy JWT Token từ Auth Service (Giả định AuthService tồn tại)
    // String? token = await AuthService.getToken();
    String? token = null; // Tạm thời null nếu chưa triển khai AuthService

    final Map<String, String> headers = {
      'Accept': 'application/json',
    };

    if (jsonType) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ✅ Phương thức POST chung
  // Dùng cho: /api/Booking
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final Uri url = Uri.parse('$_myApiBaseUrl$endpoint');
    print('POST: $url');
    try {
      return await http.post(
        url,
        headers:
            await _getAuthHeaders(), // Mặc định Content-Type: application/json
        body: json.encode(body),
      );
    } on SocketException {
      throw const SocketException('Lỗi kết nối mạng hoặc server offline.');
    } catch (e) {
      throw Exception('Lỗi kết nối POST: $e');
    }
  }

  // ✅ Phương thức PUT chung
  // Dùng cho: /api/Booking/{id}/cancel
  Future<http.Response> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    final Uri url = Uri.parse('$_myApiBaseUrl$endpoint');
    print('PUT: $url');
    try {
      return await http.put(
        url,
        headers: await _getAuthHeaders(),
        body: body != null ? json.encode(body) : null,
      );
    } on SocketException {
      throw const SocketException('Lỗi kết nối mạng hoặc server offline.');
    } catch (e) {
      throw Exception('Lỗi kết nối PUT: $e');
    }
  }
}
