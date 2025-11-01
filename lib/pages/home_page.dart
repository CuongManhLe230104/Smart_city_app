import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'settings_page.dart';
import '../pages/start_page.dart';
import 'placeholder_page.dart';
import 'package:smart_city/services/api_service.dart';
// import 'test_api_page.dart'; // Xóa vì không dùng nữa
import './test_map_page.dart'; // <-- 1. SỬA LỖI IMPORT
import 'bus_routes_page.dart';

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
      const PlaceholderPage(title: 'Bản đồ Vũng Tàu'),
      const SettingsPage(),
    ];
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const StartPage()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Trang chủ'
              : (_currentIndex == 1 ? 'Bản đồ Vũng Tàu' : 'Cài đặt'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
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

  @override
  void initState() {
    super.initState();
    // 3. Gọi API khi widget được tải
    _fetchWeather();
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
        onTap: () => _navigateTo(
          context,
          const PlaceholderPage(title: 'Tìm kiếm địa điểm'),
        ),
      ),
      _FunctionItem(
        title: 'Phản ánh góp ý',
        icon: Icons.edit_note,
        onTap: () => _navigateTo(
          context,
          const PlaceholderPage(title: 'Phản ánh góp ý'),
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
        onTap: () => _navigateTo(
          context,
          const PlaceholderPage(title: 'Mức mưa, ngập nước'),
        ),
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
                // 5. Cập nhật UI thời tiết
                _isLoadingWeather
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _weatherResult, // Hiển thị kết quả API
                        style: TextStyle(
                          fontSize: 16,
                          // Đổi màu nếu là lỗi
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
                ), // Dùng user
                const SizedBox(height: 4),
                // --- 3. SỬ DỤNG NGÀY ĐÃ ĐỊNH DẠNG ---
                Text(
                  formattedDate, // Thay thế cho '23/10/2025'
                  style: const TextStyle(fontSize: 16),
                ),
                // ------------------------------------
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- Banner sự kiện ---
        Text(
          'Sự kiện nổi bật',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 150,
            color: Colors.blueGrey.shade100,
            child: const Center(
              child: Text(
                'Banner sự kiện (Chợ quê...)',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            ),
          ),
        ),
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
