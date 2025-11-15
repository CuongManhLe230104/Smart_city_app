import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'settings_page.dart';
import 'placeholder_page.dart';
import 'package:smart_city/services/api_service.dart';
import './test_map_page.dart';
import 'bus_routes_page.dart';
import 'search_page.dart';
import '../models/event_banner_model.dart';
import '../auth/screens/login_screen.dart';
import '../pages/public_feedback_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flood_report_page.dart';
import 'flood_map_page.dart';
import 'all_flood_reports_page.dart'; // ✅ Thêm import

class HomePage extends StatefulWidget {
  final UserModel user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeTab(user: widget.user),
      SettingsPage(user: widget.user), // ⭐ Thêm settings page
    ];
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Xóa token và user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 // ⭐ Chỉ hiện AppBar ở Home tab
          ? AppBar(
              title: const Text('Trang chủ'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Đăng xuất',
                  onPressed: _logout,
                ),
              ],
            )
          : null, // Settings Page có AppBar riêng
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

// Lớp helper nhỏ cho các item trong grid
class _FunctionItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _FunctionItem({required this.title, required this.icon, required this.onTap});
}

// --- BƯỚC 1: THÊM LẠI LỚP STATFULWIDGET BỊ THIẾU ---
class HomeTab extends StatefulWidget {
  final UserModel user;
  const HomeTab({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}
// --------------------------------------------------

// Widget mới chứa toàn bộ nội dung của Tab Trang chủ
// (Đây là State, code của bạn đã có phần này)
class _HomeTabState extends State<HomeTab> {
  // 1. Tạo biến state để lưu kết quả thời tiết
  String _weatherResult = 'Đang tải thời tiết...';
  bool _isLoadingWeather = true;

  // 2. Tạo instance của ApiService
  final ApiService _apiService = ApiService();
  late Future<List<EventBannerModel>> _bannersFuture;

  @override
  void initState() {
    super.initState();
    // 3. Gọi API khi widget được tải
    _fetchWeather();
    _bannersFuture = _apiService.fetchEventBanners();
  }

  // 4. Hàm gọi API
  Future<void> _fetchWeather() async {
    // Không cần setState _isLoading = true vì đã set ở giá trị khởi tạo
    final String result = await _apiService.fetchWeather();
    // Cập nhật UI khi có kết quả
    if (mounted) {
      setState(() {
        _weatherResult = result;
        _isLoadingWeather = false;
      });
    }
  }

  // Helper điều hướng
  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildBannerSection() {
    return SizedBox(
      height: 150, // Giữ chiều cao 150
      child: FutureBuilder<List<EventBannerModel>>(
        future: _bannersFuture,
        builder: (context, snapshot) {
          // A. Đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Hiển thị khung chờ
            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                color: Colors.blueGrey.shade100,
                child: const Center(child: CircularProgressIndicator()),
              ),
            );
          }

          // B. Bị lỗi
          if (snapshot.hasError) {
            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                color: Colors.red.shade100,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Lỗi tải sự kiện:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ),
              ),
            );
          }

          // C. Không có dữ liệu
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có sự kiện nào.'));
          }

          // D. Có dữ liệu -> Hiển thị PageView
          final banners = snapshot.data!;
          return PageView.builder(
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                ), // Thêm khoảng cách
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // --- Hình ảnh (Lấy từ URL) ---
                    Image.network(
                      banner.imageUrl,
                      fit: BoxFit.cover,
                      // Hiển thị loading/lỗi cho từng ảnh
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                    // --- Lớp phủ (overlay) màu đen mờ ---
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    // --- Văn bản (Tiêu đề, Mô tả) ---
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 3, color: Colors.black),
                              ],
                            ),
                          ),
                          if (banner.description != null)
                            Text(
                              banner.description!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                shadows: [
                                  Shadow(blurRadius: 3, color: Colors.black),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ Thêm method mới
  void _showFloodReportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Báo cáo ngập lụt',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ✅ Xem tất cả báo cáo
            ListTile(
              leading: const Icon(Icons.list, color: Colors.blue, size: 32),
              title: const Text('Xem tất cả báo cáo'),
              subtitle: const Text('Xem báo cáo từ mọi người'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _navigateTo(context, const AllFloodReportsPage());
              },
            ),
            const Divider(),

            // Báo cáo mới
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red, size: 32),
              title: const Text('Báo cáo ngập lụt'),
              subtitle: const Text('Gửi báo cáo mới về điểm ngập'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _navigateTo(context, FloodReportPage(user: widget.user));
              },
            ),
            const Divider(),

            // Xem bản đồ
            ListTile(
              leading: const Icon(Icons.map, color: Colors.green, size: 32),
              title: const Text('Xem bản đồ ngập'),
              subtitle: const Text('Xem điểm ngập trên bản đồ'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _navigateTo(context, const FloodMapPage());
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- 3. LẤY VÀ ĐỊNH DẠNG NGÀY HIỆN TẠI ---
    final now = DateTime.now();
    // Định dạng ngày: vd 01/11/2025
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    final String formattedDate = "$day/$month/$year";
    // ------------------------------------------

    // --- BƯỚC 2: SỬA LẠI DANH SÁCH CHỨC NĂNG BỊ THIẾU ---
    final List<_FunctionItem> functionItems = [
      _FunctionItem(
        title: 'Bản đồ',
        icon: Icons.map_outlined,
        // SỬA: Trỏ đến trang Search
        onTap: () => _navigateTo(context, const MapTestPage()),
      ),
      _FunctionItem(
        title: 'Tuyến xe buýt',
        icon: Icons.directions_bus,
        // --- 2. SỬA LỖI Ở ĐÂY ---
        onTap: () => _navigateTo(
          context,
          const BusRoutesPage(), // Trỏ đến trang xe buýt thật
        ),
      ),
      _FunctionItem(
        title: 'Tìm kiếm địa điểm',
        icon: Icons.search,
        // SỬA: Trỏ đến trang Search
        onTap: () => _navigateTo(context, const SearchPage()),
      ),
      _FunctionItem(
        title: 'Phản ánh góp ý',
        icon: Icons.forum,
        onTap: () => _navigateTo(
          context,
          PublicFeedbacksScreen(user: widget.user),
        ),
      ),
      _FunctionItem(
        title: 'Du lịch & Ẩm thực',
        icon: Icons.restaurant_menu,
        onTap: () => _navigateTo(
          context,
          const PlaceholderPage(title: 'Du lịch & Ẩm thực'),
        ),
      ),
      _FunctionItem(
        title: 'Mức mưa, ngập',
        icon: Icons.water_drop_outlined,
        onTap: () => _showFloodReportBottomSheet(context), // ✅ Sửa dòng này
      ),
      _FunctionItem(
        title: 'Ưu đãi',
        icon: Icons.percent,
        onTap: () =>
            _navigateTo(context, const PlaceholderPage(title: 'Ưu đãi')),
      ),
      _FunctionItem(
        title: 'Xem tất cả',
        icon: Icons.grid_view,
        onTap: () => _navigateTo(
          context,
          const PlaceholderPage(title: 'Tất cả chức năng'),
        ),
      ),
    ];
    // -------------------------------------------------

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Header (Thời tiết, Chào mừng) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // --- Cột bên trái (Thời tiết) ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TP. Vũng Tàu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _isLoadingWeather
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _weatherResult,
                        style: TextStyle(
                          fontSize: 16,
                          color: _weatherResult.startsWith('Lỗi:')
                              ? Colors.red
                              : null,
                        ),
                      ),
              ],
            ),
            // --- Cột bên phải (Chào mừng) ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Chào, ${widget.user.username}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(formattedDate, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- Banner sự kiện ---
        _buildBannerSection(),
        const SizedBox(height: 24),

        // --- Grid chức năng ---
        Text(
          'Cổng thông tin',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: functionItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = functionItems[index];
            return InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 36,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
