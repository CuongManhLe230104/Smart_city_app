import 'package:flutter/material.dart';
import '../services/floodreport_service.dart';
import '../models/flood_report_model.dart';
import 'package:intl/intl.dart';

class AllFloodReportsPage extends StatefulWidget {
  const AllFloodReportsPage({super.key}); // ✅ Thêm const ở đây

  @override
  State<AllFloodReportsPage> createState() => _AllFloodReportsPageState();
}

class _AllFloodReportsPageState extends State<AllFloodReportsPage> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<FloodReportModel> _reports = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // ✅ Thay đổi: Lấy TẤT CẢ báo cáo thay vì chỉ approved
      final result = await FloodReportService.getAllReports(
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      if (result['success']) {
        setState(() {
          _reports = (result['data'] as List)
              .map((json) => FloodReportModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Không thể tải dữ liệu';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ Sửa _filteredReports để load lại khi filter thay đổi
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo ngập lụt'),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Tất cả', Icons.list),
                  const SizedBox(width: 8),
                  _buildFilterChip('Approved', 'Đã duyệt',
                      Icons.check_circle), // ✅ Capitalize
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'Pending', 'Chờ duyệt', Icons.schedule), // ✅ Capitalize
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'Rejected', 'Từ chối', Icons.cancel), // ✅ Capitalize
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadReports,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _reports.isEmpty // ✅ Thay _filteredReports thành _reports
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.water_drop_outlined,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                const Text(
                                  'Chưa có báo cáo nào',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadReports,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount:
                                  _reports.length, // ✅ Thay _filteredReports
                              itemBuilder: (context, index) {
                                final report =
                                    _reports[index]; // ✅ Thay _filteredReports
                                return _buildReportCard(report);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _loadReports(); // ✅ Load lại data khi filter thay đổi
      },
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue,
    );
  }

  Widget _buildReportCard(FloodReportModel report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh
            if (report.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  report.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image,
                        size: 64, color: Colors.grey),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + Water Level
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(report.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getStatusColor(report.status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStatusText(report.status),
                          style: TextStyle(
                            color: _getStatusColor(report.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getWaterLevelColor(report.waterLevel)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getWaterLevelColor(report.waterLevel),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop,
                              size: 14,
                              color: _getWaterLevelColor(report.waterLevel),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getWaterLevelText(report.waterLevel),
                              style: TextStyle(
                                color: _getWaterLevelColor(report.waterLevel),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (report.description != null &&
                      report.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      report.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Location
                  if (report.address != null && report.address!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.red.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.address!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  // Date + User
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.person, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        report.userName ?? 'Anonymous',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDetails(FloodReportModel report) {
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
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Image
              if (report.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    report.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, size: 64),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Title
              Text(
                report.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Status + Water Level
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    _getStatusText(report.status),
                    _getStatusColor(report.status),
                    Icons.info,
                  ),
                  _buildInfoChip(
                    _getWaterLevelText(report.waterLevel),
                    _getWaterLevelColor(report.waterLevel),
                    Icons.water_drop,
                  ),
                ],
              ),

              if (report.description != null &&
                  report.description!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Mô tả',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  report.description!,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ],

              if (report.address != null && report.address!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Địa điểm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report.address!,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
              const Text(
                'Thông tin',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Người báo cáo', report.userName ?? 'Anonymous',
                  Icons.person),
              _buildInfoRow(
                'Ngày báo cáo',
                DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt),
                Icons.calendar_today,
              ),
              if (report.approvedAt != null)
                _buildInfoRow(
                  'Ngày duyệt',
                  DateFormat('dd/MM/yyyy HH:mm').format(report.approvedAt!),
                  Icons.check_circle,
                ),

              if (report.adminNote != null && report.adminNote!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings,
                              color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Ghi chú từ Admin',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(report.adminNote!),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Thêm các helper methods này
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Đã duyệt';
      case 'pending':
        return 'Chờ duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }

  Color _getWaterLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return Colors.yellow.shade700;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getWaterLevelText(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      case 'critical':
        return 'Nguy hiểm';
      default:
        return 'Không rõ';
    }
  }
}
