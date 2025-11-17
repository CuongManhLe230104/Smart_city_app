import 'package:flutter/material.dart';
import '../services/floodreport_service.dart';
import '../models/flood_report_model.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';

class MyFloodReportsPage extends StatefulWidget {
  final UserModel user;

  const MyFloodReportsPage({super.key, required this.user});

  @override
  State<MyFloodReportsPage> createState() => _MyFloodReportsPageState();
}

class _MyFloodReportsPageState extends State<MyFloodReportsPage> {
  List<FloodReportModel> _reports = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _selectedStatus;

  final Map<String, String> _statuses = {
    'Tất cả': '',
    'Chờ duyệt': 'Pending',
    'Đã duyệt': 'Approved',
    'Từ chối': 'Rejected',
  };

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
      final result = await FloodReportService.getMyReports(
        widget.user.id,
        status: _selectedStatus,
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
          _errorMessage = result['message'];
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo trạng thái'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _statuses.keys.map((status) {
            final isSelected = _selectedStatus == _statuses[status] ||
                (_selectedStatus == null && status == 'Tất cả');
            return RadioListTile<String>(
              title: Text(status),
              value: _statuses[status]!,
              groupValue: _selectedStatus ?? '',
              selected: isSelected,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value == '' ? null : value;
                });
                Navigator.pop(context);
                _loadReports();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo của tôi'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Lọc',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đây là các báo cáo ngập lụt bạn đã gửi. Admin sẽ đánh giá mức độ ngập sau khi duyệt.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
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
                            Icon(Icons.error,
                                size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(_errorMessage),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _loadReports,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _reports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox,
                                    size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'Bạn chưa có báo cáo nào',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nhấn nút + để gửi báo cáo đầu tiên',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadReports,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _reports.length,
                              itemBuilder: (context, index) {
                                final report = _reports[index];
                                return _MyReportCard(report: report);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _MyReportCard extends StatelessWidget {
  final FloodReportModel report;

  const _MyReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetailDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Tiêu đề + Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(report.status),
                ],
              ),
              const SizedBox(height: 12),

              // Ảnh
              if (report.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    report.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 48),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),

              // Mức nước
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getWaterLevelColor(report.waterLevel)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _getWaterLevelColor(report.waterLevel)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.water_drop,
                            size: 16,
                            color: _getWaterLevelColor(report.waterLevel)),
                        const SizedBox(width: 4),
                        Text(
                          'Mức nước: ${_getWaterLevelText(report.waterLevel)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getWaterLevelColor(report.waterLevel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Địa chỉ
              if (report.address != null && report.address!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.address!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // Thời gian
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),

              // Admin note (nếu có)
              if (report.adminNote != null && report.adminNote!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.admin_panel_settings,
                          size: 20, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ghi chú từ Admin:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              report.adminNote!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case 'Approved':
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Đã duyệt';
        break;
      case 'Rejected':
        color = Colors.red;
        icon = Icons.cancel;
        text = 'Từ chối';
        break;
      default:
        color = Colors.orange;
        icon = Icons.schedule;
        text = 'Chờ duyệt';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getWaterLevelColor(String waterLevel) {
    switch (waterLevel) {
      case 'Critical':
        return Colors.purple;
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.yellow.shade700;
      case 'Unknown':
      default:
        return Colors.grey;
    }
  }

  String _getWaterLevelText(String waterLevel) {
    switch (waterLevel) {
      case 'Critical':
        return 'Nguy hiểm (>50cm)';
      case 'High':
        return 'Cao (30-50cm)';
      case 'Medium':
        return 'Trung bình (15-30cm)';
      case 'Low':
        return 'Thấp (<15cm)';
      case 'Unknown':
      default:
        return 'Chưa đánh giá';
    }
  }

  void _showDetailDialog(BuildContext context) {
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
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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
                const SizedBox(height: 24),

                // Tiêu đề + Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusChip(report.status),
                  ],
                ),
                const SizedBox(height: 16),

                // Ảnh
                if (report.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      report.imageUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),

                // Mô tả
                if (report.description != null &&
                    report.description!.isNotEmpty) ...[
                  _buildInfoRow(
                      Icons.description, 'Mô tả', report.description!),
                  const SizedBox(height: 12),
                ],

                // Địa chỉ
                _buildInfoRow(Icons.location_on, 'Địa chỉ',
                    report.address ?? 'Không xác định'),
                const SizedBox(height: 12),

                // Mức nước
                _buildInfoRow(
                  Icons.water_drop,
                  'Mức nước',
                  _getWaterLevelText(report.waterLevel),
                  valueColor: _getWaterLevelColor(report.waterLevel),
                ),
                const SizedBox(height: 12),

                // Tọa độ
                _buildInfoRow(
                  Icons.my_location,
                  'Tọa độ',
                  'Lat: ${report.latitude.toStringAsFixed(6)}, Lon: ${report.longitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 12),

                // Thời gian báo cáo
                _buildInfoRow(
                  Icons.calendar_today,
                  'Thời gian báo cáo',
                  DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt),
                ),

                if (report.approvedAt != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.check_circle,
                    'Thời gian duyệt',
                    DateFormat('dd/MM/yyyy HH:mm').format(report.approvedAt!),
                  ),
                ],

                // Admin note
                if (report.adminNote != null &&
                    report.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
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
                            Text(
                              'Ghi chú từ Admin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          report.adminNote!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
