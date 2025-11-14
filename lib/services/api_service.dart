import 'dart:convert'; // SỬA: Dùng dấu hai chấm (:)
import 'package:http/http.dart' as http; // SỬA: Dùng dấu hai chấm (:)
import '../models/bus_route_model.dart';
import '../models/location_search_result.dart';
import '../models/event_banner_model.dart';

class ApiService {
  // --- 1. API THỜI TIẾT ---
  static const String _weatherApiKey = 'b19130f92ebc617c3b3f0d52f0178d18';
  static const String _weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  Future<String> fetchWeather() async {
    if (_weatherApiKey == 'YOUR_API_KEY_HERE') {
      return 'Lỗi: Chưa có API Key';
    }
    try {
      const String lat = '10.4113';
      const String lon = '107.1362';
      final Uri url = Uri.parse(
        '$_weatherBaseUrl/weather?lat=$lat&lon=$lon&appid=$_weatherApiKey&units=metric&lang=vi',
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

  // --- 2. API BẢN ĐỒ ---
  static const String _mapApiKey = 'pk.775aea632346a6c8295fe849c170b94b';
  static const String _mapBaseUrl = 'https://us1.locationiq.com/v1';

  Future<Map<String, double>> fetchMapCoordinates() async {
    try {
      const String query = 'Vung Tau, Ba Ria - Vung Tau, Vietnam';
      final Uri url = Uri.parse(
        '$_mapBaseUrl/search?key=$_mapApiKey&q=$query&format=json',
      );
      final http.Response response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final Map<String, dynamic> firstResult = data[0];

          // SỬA: Parse string sang double và trả về Map
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

  // --- 3. API BACKEND CỦA BẠN ---
  static const String _myApiBaseUrl = 'http://10.0.2.2:5000';

  Future<List<BusRouteModel>> fetchBusRoutes() async {
    final Uri url = Uri.parse('$_myApiBaseUrl/api/BusRoutes');
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

  // --- 4. HÀM MỚI BỊ THIẾU ĐỂ GỌI API SEARCH ---
  Future<List<LocationSearchResult>> searchLocations(String query) async {
    // Tạo URL với query (đã được mã hóa)
    final Uri url = Uri.parse(
      '$_myApiBaseUrl/api/search',
    ).replace(queryParameters: {'q': query});

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

      // Chuyển JSON (List) sang List<LocationSearchResult>
      return jsonData
          .map((json) => LocationSearchResult.fromJson(json))
          .toList();
    } else {
      throw Exception('Lỗi server (Search): ${response.statusCode}');
    }
  }

  Future<List<EventBannerModel>> fetchEventBanners() async {
    final Uri url = Uri.parse('$_myApiBaseUrl/api/EventBanners');
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
      return jsonData.map((json) => EventBannerModel.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi khi tải banner sự kiện: ${response.statusCode}');
    }
  }

  // Thêm method tìm kiếm bus routes
  Future<List<BusRouteModel>> searchBusRoutes(String query) async {
    final Uri url = Uri.parse('$_myApiBaseUrl/api/BusRoutes/search')
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

  // Thêm method lấy chi tiết bus route
  Future<BusRouteModel> getBusRouteDetail(int id) async {
    final Uri url = Uri.parse('$_myApiBaseUrl/api/BusRoutes/$id');
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
}
