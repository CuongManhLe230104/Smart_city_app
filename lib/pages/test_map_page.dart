import 'package:flutter/material.dart';
// Đảm bảo đường dẫn này đúng (nếu api_service.dart nằm trong lib/services/)
import '../services/api_service.dart';

class MapTestPage extends StatefulWidget {
  const MapTestPage({super.key});

  @override
  State<MapTestPage> createState() => _MapTestPageState();
}

class _MapTestPageState extends State<MapTestPage> {
  // Biến để lưu kết quả API
  String _apiResult = 'Đang gọi API...';
  bool _isLoading = true; // Bắt đầu ở trạng thái tải
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Tự động gọi API khi trang này được mở
    _handleCallApi();
  }

  // Hàm để gọi API
  Future<void> _handleCallApi() async {
    // Nếu hàm này được gọi từ nút bấm (không phải initState)
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
        _apiResult = 'Đang tải...';
      });
    }

    // Gọi hàm fetchMapCoordinates và chờ kết quả
    final String result = await _apiService.fetchMapCoordinates();

    // Cập nhật UI với kết quả nhận được (nếu trang còn tồn tại)
    if (mounted) {
      setState(() {
        _isLoading = false;
        _apiResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thành Phố Vũng Tàu')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Nút bấm để kích hoạt (gọi lại)
              const SizedBox(height: 30),

              // Hiển thị vòng quay loading hoặc kết quả
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Text(
                  _apiResult, // Hiển thị kết quả ở đây
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
