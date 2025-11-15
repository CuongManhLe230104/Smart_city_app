import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/flood_report_model.dart';
import '../services/floodreport_service.dart';

class FloodMapPage extends StatefulWidget {
  const FloodMapPage({super.key});

  @override
  State<FloodMapPage> createState() => _FloodMapPageState();
}

class _FloodMapPageState extends State<FloodMapPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  List<FloodReportModel> _reports = [];

  // Vị trí mặc định (Vũng Tàu)
  static const LatLng _vungTau = LatLng(10.3460, 107.0844);

  @override
  void initState() {
    super.initState();
    _loadFloodReports();
  }

  Future<void> _loadFloodReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FloodReportService.getApprovedReports();

      if (result['success']) {
        final List<dynamic> data = result['data'];
        _reports = data.map((json) => FloodReportModel.fromJson(json)).toList();

        // Tạo markers
        _markers.clear();
        for (var report in _reports) {
          _markers.add(
            Marker(
              markerId: MarkerId('flood_${report.id}'),
              position: LatLng(report.latitude, report.longitude),
              icon: _getMarkerIcon(report.waterLevel),
              infoWindow: InfoWindow(
                title: report.title,
                snippet: report.getWaterLevelText(),
                onTap: () => _showReportDetail(report),
              ),
            ),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  BitmapDescriptor _getMarkerIcon(String waterLevel) {
    // TODO: Tạo custom marker icons
    return BitmapDescriptor.defaultMarkerWithHue(
      waterLevel == 'Critical'
          ? BitmapDescriptor.hueViolet
          : waterLevel == 'High'
              ? BitmapDescriptor.hueRed
              : waterLevel == 'Medium'
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueYellow,
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

              // Ảnh
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  report.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Tiêu đề
              Text(
                report.title,
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
                        color: Color.lerp(report.getWaterLevelColor(),
                            Colors.black, 0.7)!, // ✅ Sửa shade800
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
              if (report.description != null) ...[
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
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
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
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _vungTau,
              zoom: 13,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),
          if (_isLoading)
            Container(
              color: Colors.white70,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Legend
          Positioned(
            top: 16,
            right: 16,
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
                    _buildLegendItem('Thấp', Colors.yellow),
                    _buildLegendItem('Trung bình', Colors.orange),
                    _buildLegendItem('Cao', Colors.red),
                    _buildLegendItem('Nguy hiểm', Colors.purple),
                  ],
                ),
              ),
            ),
          ),

          // Số lượng điểm
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '📍 ${_reports.length} điểm ngập đang được theo dõi',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: 20, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
