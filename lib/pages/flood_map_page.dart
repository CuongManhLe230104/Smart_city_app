import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../models/flood_report_model.dart';
import '../services/floodreport_service.dart';

class FloodMapPage extends StatefulWidget {
  const FloodMapPage({super.key});

  @override
  State<FloodMapPage> createState() => _FloodMapPageState();
}

class _FloodMapPageState extends State<FloodMapPage> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  bool _isLoading = true;
  List<FloodReportModel> _reports = [];
  String? _errorMessage;

  // Vị trí mặc định (Vũng Tàu)
  static const latlong.LatLng _vungTau = latlong.LatLng(10.3460, 107.0844);

  // Filter theo mức độ ngập
  String? _selectedWaterLevel;
  final List<String> _waterLevels = [
    'All',
    'Low',
    'Medium',
    'High',
    'Dangerous',
  ];

  @override
  void initState() {
    super.initState();
    _loadFloodReports();
  }

  Future<void> _loadFloodReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FloodReportService.getApprovedReports();

      debugPrint('API Response: $result');

      if (result['success'] == true) {
        final data = result['data'];

        if (data is List) {
          _reports = data
              .map((json) {
                try {
                  return FloodReportModel.fromJson(json);
                } catch (e) {
                  debugPrint('Lỗi parse report: $e');
                  return null;
                }
              })
              .whereType<FloodReportModel>()
              .toList();

          debugPrint('✅ Loaded ${_reports.length} reports');

          _updateMarkers();
        } else {
          _errorMessage = 'Dữ liệu không đúng định dạng';
        }
      } else {
        _errorMessage =
            result['message']?.toString() ?? 'Không thể tải dữ liệu';
      }
    } catch (e, stackTrace) {
      debugPrint('Lỗi tải dữ liệu: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = 'Lỗi: $e';
    }

    setState(() {
      _isLoading = false;
    });

    if (_errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: _loadFloodReports,
          ),
        ),
      );
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // Lọc reports theo mức độ ngập
    final filteredReports = _selectedWaterLevel == null ||
            _selectedWaterLevel == 'All'
        ? _reports
        : _reports.where((r) => r.waterLevel == _selectedWaterLevel).toList();

    for (var report in filteredReports) {
      if (report.latitude != 0 && report.longitude != 0) {
        _markers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: latlong.LatLng(report.latitude, report.longitude),
            child: GestureDetector(
              onTap: () => _showReportDetail(report),
              child: Tooltip(
                message: report.title ?? 'Không có tiêu đề',
                child: Icon(
                  Icons.location_pin,
                  color: _getMarkerColor(report.waterLevel ?? 'Low'),
                  size: 40,
                ),
              ),
            ),
          ),
        );
      }
    }

    debugPrint('✅ Created ${_markers.length} markers');
  }

  Color _getMarkerColor(String waterLevel) {
    switch (waterLevel) {
      case 'Dangerous':
        return Colors.purple;
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
      default:
        return Colors.yellow.shade700;
    }
  }

  // ✅ THÊM: Hiển thị danh sách điểm ngập
  void _showFloodLocationsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          // Lọc reports theo filter hiện tại
          final filteredReports =
              _selectedWaterLevel == null || _selectedWaterLevel == 'All'
                  ? _reports
                  : _reports
                      .where((r) => r.waterLevel == _selectedWaterLevel)
                      .toList();

          return Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Danh sách điểm ngập (${filteredReports.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Danh sách
              Expanded(
                child: filteredReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không có điểm ngập nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredReports.length,
                        itemBuilder: (context, index) {
                          final report = filteredReports[index];
                          return _buildLocationListItem(report);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ THÊM: Widget item trong danh sách
  Widget _buildLocationListItem(FloodReportModel report) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          // Đóng bottom sheet
          Navigator.pop(context);

          // Di chuyển đến vị trí
          _mapController.move(
            latlong.LatLng(report.latitude, report.longitude),
            16.0,
          );

          // Hiển thị detail sau 500ms
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showReportDetail(report);
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon mức độ ngập
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: report.getWaterLevelColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: report.getWaterLevelColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Nội dung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề
                    Text(
                      report.title ?? 'Không có tiêu đề',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Địa chỉ
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.address ?? 'Không có địa chỉ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Mức độ + Thời gian
                    Row(
                      children: [
                        // Mức độ ngập
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: report.getWaterLevelColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            report.getWaterLevelText(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: report.getWaterLevelColor(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Thời gian
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTimeShort(
                            report.approvedAt ?? report.createdAt,
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetail(FloodReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ảnh từ server
              if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    report.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'Không thể tải ảnh',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),

              // Tiêu đề
              Text(
                report.title ?? 'Không có tiêu đề',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Mức độ ngập
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: report.getWaterLevelColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: report.getWaterLevelColor(),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop,
                      size: 16,
                      color: report.getWaterLevelColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Mức độ: ${report.getWaterLevelText()}',
                      style: TextStyle(
                        color: Color.lerp(
                            report.getWaterLevelColor(), Colors.black, 0.7)!,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Địa chỉ
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.address ?? 'Không có địa chỉ',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Mô tả
              if (report.description != null &&
                  report.description!.isNotEmpty) ...[
                const Text(
                  'Mô tả:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(report.description!),
                const SizedBox(height: 12),
              ],

              // Thời gian
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Báo cáo lúc: ${_formatDateTime(report.approvedAt ?? report.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Button di chuyển đến vị trí
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _mapController.move(
                      latlong.LatLng(report.latitude, report.longitude),
                      16.0,
                    );
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Xem trên bản đồ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Không rõ';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ✅ THÊM: Format ngắn gọn cho danh sách
  String _formatDateTimeShort(DateTime? dt) {
    if (dt == null) return 'N/A';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ ngập lụt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFloodReports,
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () {
              _mapController.move(_vungTau, 13.0);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadFloodReports,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Bản đồ OpenStreetMap
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _vungTau,
                        initialZoom: 13.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.smart_city',
                        ),
                        MarkerLayer(markers: _markers),
                      ],
                    ),

                    // Filter chips
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Card(
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _waterLevels.length,
                            itemBuilder: (context, index) {
                              final level = _waterLevels[index];
                              final isSelected = _selectedWaterLevel == level ||
                                  (_selectedWaterLevel == null &&
                                      level == 'All');

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: FilterChip(
                                  label: Text(level),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedWaterLevel =
                                          level == 'All' ? null : level;
                                      _updateMarkers();
                                    });
                                  },
                                  backgroundColor: level == 'All'
                                      ? Colors.grey.shade200
                                      : _getMarkerColor(level).withOpacity(0.2),
                                  selectedColor: level == 'All'
                                      ? Colors.blue.shade100
                                      : _getMarkerColor(level).withOpacity(0.4),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Legend
                    Positioned(
                      top: 70,
                      right: 10,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Mức độ ngập',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _buildLegendItem('Thấp', Colors.yellow.shade700),
                              _buildLegendItem('Trung bình', Colors.orange),
                              _buildLegendItem('Cao', Colors.red),
                              _buildLegendItem('Nguy hiểm', Colors.purple),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

      // ✅ THÊM: Floating Action Button hiển thị danh sách
      floatingActionButton: _isLoading || _reports.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _showFloodLocationsList,
              icon: const Icon(Icons.list_alt),
              label: Text('Danh sách (${_reports.length})'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_pin, size: 20, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
