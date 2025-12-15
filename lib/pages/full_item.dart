import 'package:flutter/material.dart';
import '../models/user_model.dart';
import './test_map_page.dart';
import 'bus_routes_page.dart';
import 'search_page.dart';
import '../pages/public_feedback_screen.dart';
import 'flood_report_page.dart';
import 'flood_map_page.dart';
import 'all_flood_reports_page.dart';
import 'tour_list_page.dart';

// Class định nghĩa item dịch vụ (đặt nội bộ trong file này)
class _ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ServiceItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class AllFunctionsPage extends StatelessWidget {
  final UserModel user;

  const AllFunctionsPage({super.key, required this.user});

  // Hàm chuyển trang chung
  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  // Logic hiển thị BottomSheet Báo cáo ngập lụt (Copy từ HomeTab sang)
  void _showFloodReportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Báo cáo ngập lụt',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildFloodOption(
              context,
              icon: Icons.list_rounded,
              title: 'Xem tất cả báo cáo',
              subtitle: 'Xem báo cáo từ cộng đồng',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _navigateTo(context, const AllFloodReportsPage());
              },
            ),
            const SizedBox(height: 12),
            _buildFloodOption(
              context,
              icon: Icons.report_rounded,
              title: 'Báo cáo ngập lụt',
              subtitle: 'Gửi báo cáo mới về điểm ngập',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _navigateTo(context, FloodReportPage(user: user));
              },
            ),
            const SizedBox(height: 12),
            _buildFloodOption(
              context,
              icon: Icons.map_rounded,
              title: 'Xem bản đồ ngập',
              subtitle: 'Xem điểm ngập trên bản đồ',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _navigateTo(context, const FloodMapPage());
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFloodOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách tất cả các chức năng (Đã loại bỏ item "Xem tất cả")
    final List<_ServiceItem> items = [
      _ServiceItem(
        title: 'Bản đồ',
        icon: Icons.map_rounded,
        color: Colors.blue,
        onTap: () => _navigateTo(context, const MapTestPage()),
      ),
      _ServiceItem(
        title: 'Tuyến xe buýt',
        icon: Icons.directions_bus_rounded,
        color: Colors.orange,
        onTap: () => _navigateTo(context, const BusRoutesPage()),
      ),
      _ServiceItem(
        title: 'Tìm kiếm',
        icon: Icons.search_rounded,
        color: Colors.purple,
        onTap: () => _navigateTo(context, const SearchPage()),
      ),
      _ServiceItem(
        title: 'Phản ánh',
        icon: Icons.forum_rounded,
        color: Colors.teal,
        onTap: () => _navigateTo(context, const PublicFeedbacksScreen()),
      ),
      _ServiceItem(
        title: 'Du lịch',
        icon: Icons.flight_takeoff_rounded,
        color: Colors.pink,
        onTap: () => _navigateTo(context, const TourListPage()),
      ),
      _ServiceItem(
        title: 'Mức mưa',
        icon: Icons.water_drop_rounded,
        color: Colors.cyan,
        onTap: () => _showFloodReportBottomSheet(context),
      ),
      // Bạn có thể thêm các chức năng khác ở đây trong tương lai
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Tất cả dịch vụ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Hiển thị 3 cột cho thoáng hơn trang chủ
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, size: 32, color: item.color),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
