import 'dart:convert'; // Để dùng jsonDecode
import 'package:http/http.dart' as http;

class ApiService {
  // --- API THỜI TIẾT OPENWEATHERMAP ---
  //
  // BƯỚC QUAN TRỌNG:
  // 1. Đăng ký tài khoản miễn phí tại: https://openweathermap.org/appid
  // 2. Lấy API Key của bạn (ví dụ: 8a1b2c3d...)
  // 3. Dán key đó vào chuỗi dưới đây:
  static const String _apiKey = 'b19130f92ebc617c3b3f0d52f0178d18';
  //
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Hàm để lấy thời tiết Vũng Tàu
  // (Sử dụng tọa độ Google Maps bạn gửi: 10.4113, 107.1362)
  Future<String> fetchWeather() async {
    // Kiểm tra xem key đã được thay đổi chưa
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      return 'Lỗi: Chưa có API Key';
    }

    try {
      // 1. Tạo URL mới
      const String lat = '10.4113';
      const String lon = '107.1362';
      final Uri url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=vi',
      );

      // 2. Gửi yêu cầu GET
      final http.Response response = await http.get(url);

      // 3. Kiểm tra mã trạng thái (200 = OK)
      if (response.statusCode == 200) {
        // 4. Giải mã (decode) JSON
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Lấy thông tin thời tiết
        String description = data['weather'][0]['description'];
        // API trả về kiểu double, ta làm tròn nó
        String temp = data['main']['temp'].toStringAsFixed(1);

        // 5. Trả về kết quả
        return "$temp°C - $description";
      } else {
        // Nếu server trả về lỗi (vd: 401 - Sai API key)
        return 'Lỗi: ${response.statusCode}';
      }
    } catch (e) {
      // Nếu có lỗi kết nối (vd: mất mạng)
      return 'Lỗi kết nối';
    }
  }

  static const String _mapApiKey = 'pk.775aea632346a6c8295fe849c170b94b';
  static const String _mapBaseUrl = 'https://us1.locationiq.com/v1';

  Future<String> fetchMapCoordinates() async {
    try {
      // 1. Tạo URL mới
      const String query = 'Vung Tau, Ba Ria - Vung Tau, Vietnam';
      final Uri url = Uri.parse(
        '$_mapBaseUrl/search?key=$_mapApiKey&q=$query&format=json',
      );

      // 2. Gửi yêu cầu GET
      final http.Response response = await http.get(url);

      // 3. Kiểm tra mã trạng thái (200 = OK)
      if (response.statusCode == 200) {
        // 4. Giải mã (decode) JSON
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          // Lấy kết quả đầu tiên
          final Map<String, dynamic> firstResult = data[0];
          final String lat = firstResult['lat'];
          final String lon = firstResult['lon'];

          // 5. Trả về tọa độ
          return "Tìm thấy Vũng Tàu!\nTọa độ (Lat/Lon): $lat / $lon";
        } else {
          return 'Lỗi: Không tìm thấy kết quả cho Vũng Tàu.';
        }
      } else {
        return 'Lỗi: ${response.statusCode}';
      }
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }
}
