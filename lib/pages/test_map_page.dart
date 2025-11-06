import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

class MapTestPage extends StatefulWidget {
  const MapTestPage({super.key});

  @override
  State<MapTestPage> createState() => _MapTestPageState();
}

class _MapTestPageState extends State<MapTestPage> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _error;
  latlong.LatLng? _vungTauCenter;
  final MapController _mapController = MapController();

  // BIẾN MỚI: Để lưu vị trí người dùng chạm vào
  latlong.LatLng? _tappedPoint;

  @override
  void initState() {
    super.initState();
    _handleCallApi();
  }

  Future<void> _handleCallApi() async {
    try {
      if (!_isLoading) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      final coords = await _apiService.fetchMapCoordinates();
      if (mounted) {
        setState(() {
          _vungTauCenter = latlong.LatLng(coords['lat']!, coords['lon']!);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ Vũng Tàu (OpenStreetMap)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleCallApi,
          ),
          // Nút để quay về tâm Vũng Tàu
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () {
              if (_vungTauCenter != null) {
                _mapController.move(_vungTauCenter!, 14.0);
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // A. Đang tải
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // B. Bị lỗi
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Lỗi: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // C. Tải thành công -> Hiển thị Map
    if (_vungTauCenter != null) {
      return FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _vungTauCenter!,
          initialZoom: 14.0,

          // --- THÊM THAO TÁC MỚI ---

          // 1. CHO PHÉP XOAY BẢN ĐỒ
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all, // Bật tất cả (bao gồm cả xoay)
          ),

          // 2. BẮT SỰ KIỆN CHẠM VÀO BẢN ĐỒ
          onTap: (tapPosition, point) {
            setState(() {
              _tappedPoint = point; // Lưu lại tọa độ điểm vừa chạm
            });
            // Hiển thị thông báo (ví dụ)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Bạn đã chạm vào: ${point.latitude}, ${point.longitude}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          // -----------------------------
        ),
        children: [
          // Lớp (Layer) bản đồ nền
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.smart_city',
          ),

          // Lớp (Layer) chứa điểm đánh dấu
          MarkerLayer(
            markers: [
              // Marker cho Vũng Tàu
              Marker(
                width: 80.0,
                height: 80.0,
                point: _vungTauCenter!,
                child: const Tooltip(
                  message: 'Trung tâm Vũng Tàu',
                  child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                ),
              ),

              // Marker cho điểm người dùng vừa chạm (nếu có)
              if (_tappedPoint != null)
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: _tappedPoint!,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.blue, // Đổi màu xanh
                    size: 40,
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return const Center(child: Text('Không có dữ liệu để hiển thị.'));
  }
}
