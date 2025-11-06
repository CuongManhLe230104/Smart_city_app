import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../services/api_service.dart';
import '../models/location_search_result.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<LocationSearchResult> _results = [];
  bool _isLoading = false;
  String? _error;
  String _currentQuery = ''; // <-- 1. Biến mới để lưu nội dung tìm kiếm

  // Tọa độ Vũng Tàu (để khởi tạo map)
  final latlong.LatLng _vungTauCenter = const latlong.LatLng(
    10.39,
    107.09,
  ); // Tọa độ trung tâm

  // Danh sách các nút lọc nhanh
  final List<String> _quickFilters = [
    'ATM',
    'Bệnh viện',
    'Cây xăng',
    'Nhà hàng',
  ];

  // Hàm thực hiện tìm kiếm
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    // Cập nhật ô text và đóng bàn phím
    _searchController.text = query;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
      _currentQuery = query.toLowerCase(); // <-- 2. Lưu lại query
    });

    try {
      final results = await _apiService.searchLocations(query);

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }

      // Nếu có kết quả, di chuyển map đến kết quả đầu tiên
      if (results.isNotEmpty && mounted) {
        _mapController.move(results.first.coords, 15.0);
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

  // --- 3. HÀM HELPER MỚI ĐỂ CHỌN ICON ---
  Widget _getMarkerIcon(String query, String displayName) {
    final lowerDisplay = displayName.toLowerCase();

    // Ưu tiên query trước
    if (query.contains('atm')) {
      return const Icon(Icons.atm, color: Colors.green, size: 40);
    }
    if (query.contains('bệnh viện') || query.contains('hospital')) {
      return const Icon(Icons.local_hospital, color: Colors.red, size: 40);
    }
    if (query.contains('cây xăng') || query.contains('gas')) {
      return const Icon(
        Icons.local_gas_station,
        color: Colors.orange,
        size: 40,
      );
    }
    if (query.contains('nhà hàng') || query.contains('restaurant')) {
      return const Icon(Icons.restaurant, color: Colors.purple, size: 40);
    }

    // Nếu query không rõ, thử check tên địa điểm
    if (lowerDisplay.contains('atm')) {
      return const Icon(Icons.atm, color: Colors.green, size: 40);
    }
    if (lowerDisplay.contains('bệnh viện') ||
        lowerDisplay.contains('hospital')) {
      return const Icon(Icons.local_hospital, color: Colors.red, size: 40);
    }
    if (lowerDisplay.contains('cây xăng') || lowerDisplay.contains('gas')) {
      return const Icon(
        Icons.local_gas_station,
        color: Colors.orange,
        size: 40,
      );
    }

    // Icon mặc định
    return const Icon(Icons.location_pin, color: Colors.blue, size: 40);
  }
  // ------------------------------------

  // Hàm tạo danh sách Markers
  List<Marker> _buildMarkers() {
    return _results.map((result) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: result.coords,
        child: Tooltip(
          message: result.displayName,
          // --- 4. SỬ DỤNG HÀM HELPER ĐỂ LẤY ICON ---
          child: _getMarkerIcon(_currentQuery, result.displayName),
        ),
      );
    }).toList();
  }

  // --- 5. WIDGET MỚI CHO CÁC NÚT LỌC NHANH ---
  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 10),
      // Dùng SingleChildScrollView để cho phép cuộn ngang
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickFilters.map((filter) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ActionChip(
                avatar: Icon(
                  filter == 'ATM'
                      ? Icons.atm
                      : filter == 'Bệnh viện'
                      ? Icons.local_hospital
                      : filter == 'Cây xăng'
                      ? Icons.local_gas_station
                      : Icons.restaurant,
                  color: Colors.black54,
                ),
                label: Text(filter),
                onPressed: () => _performSearch(filter), // Bấm để tìm
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  // ---------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm Địa điểm')),
      body: Stack(
        children: [
          // 1. BẢN ĐỒ
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _vungTauCenter,
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smart_city',
              ),
              MarkerLayer(markers: _buildMarkers()), // Hiển thị các marker
            ],
          ),

          // 2. THANH TÌM KIẾM VÀ LỌC
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm ATM, bệnh viện, trạm xăng...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () =>
                                  _performSearch(_searchController.text),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onSubmitted: _performSearch, // Tự tìm khi bấm Enter
                  ),

                  // --- 6. THÊM CÁC NÚT LỌC VÀO UI ---
                  _buildFilterChips(),
                  const SizedBox(height: 4), // Thêm 1 chút đệm
                  // ---------------------------------
                ],
              ),
            ),
          ),

          // 3. HIỂN THỊ LỖI (NẾU CÓ)
          if (_error != null)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Card(
                color: Colors.red.shade800,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
