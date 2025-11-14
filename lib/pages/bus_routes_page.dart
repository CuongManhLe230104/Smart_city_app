import 'package:flutter/material.dart';
import '../models/bus_route_model.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BusRoutesPage extends StatefulWidget {
  const BusRoutesPage({super.key});

  @override
  State<BusRoutesPage> createState() => _BusRoutesPageState();
}

class _BusRoutesPageState extends State<BusRoutesPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<BusRouteModel> _allRoutes = [];
  List<BusRouteModel> _displayedRoutes = [];
  Set<int> _favoriteRoutes = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadFavorites();
    await _loadBusRoutes();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorite_bus_routes');
    if (favoritesJson != null) {
      final List<dynamic> favoritesList = jsonDecode(favoritesJson);
      setState(() {
        _favoriteRoutes = favoritesList.cast<int>().toSet();
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'favorite_bus_routes',
      jsonEncode(_favoriteRoutes.toList()),
    );
  }

  Future<void> _loadBusRoutes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final routes = await _apiService.fetchBusRoutes();
      setState(() {
        _allRoutes = routes;
        _displayedRoutes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _searchRoutes(String query) {
    if (query.isEmpty) {
      setState(() {
        _displayedRoutes = _allRoutes;
      });
      return;
    }

    setState(() {
      _displayedRoutes = _allRoutes.where((route) {
        return route.routeNumber.toLowerCase().contains(query.toLowerCase()) ||
            route.routeName.toLowerCase().contains(query.toLowerCase()) ||
            (route.startPoint?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            (route.endPoint?.toLowerCase().contains(query.toLowerCase()) ??
                false);
      }).toList();
    });
  }

  void _toggleFavorite(int routeId) {
    setState(() {
      if (_favoriteRoutes.contains(routeId)) {
        _favoriteRoutes.remove(routeId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Đã xóa khỏi yêu thích')),
        );
      } else {
        _favoriteRoutes.add(routeId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⭐ Đã thêm vào yêu thích')),
        );
      }
    });
    _saveFavorites();
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lọc tuyến xe',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Tuyến yêu thích'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _displayedRoutes = _allRoutes
                      .where((r) => _favoriteRoutes.contains(r.id))
                      .toList();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive, color: Colors.blue),
              title: const Text('Tất cả tuyến'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _displayedRoutes = _allRoutes;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuyến xe buýt'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: TextField(
              controller: _searchController,
              onChanged: _searchRoutes,
              decoration: InputDecoration(
                hintText: 'Tìm tuyến xe...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchRoutes('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Body
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
                            Text(_errorMessage, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _loadBusRoutes,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _displayedRoutes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_bus,
                                    size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'Không tìm thấy tuyến xe nào',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadBusRoutes,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _displayedRoutes.length,
                              itemBuilder: (context, index) {
                                final route = _displayedRoutes[index];
                                final isFavorite =
                                    _favoriteRoutes.contains(route.id);
                                return _BusRouteCard(
                                  route: route,
                                  isFavorite: isFavorite,
                                  onFavoriteTap: () =>
                                      _toggleFavorite(route.id),
                                  onTap: () => _showRouteDetail(route),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _showRouteDetail(BusRouteModel route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusRouteDetailPage(route: route),
      ),
    );
  }
}

class _BusRouteCard extends StatelessWidget {
  final BusRouteModel route;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const _BusRouteCard({
    required this.route,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Route number badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        route.routeNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Route info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.routeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (route.description != null)
                          Text(
                            route.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Favorite button
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.amber : Colors.grey,
                    ),
                    onPressed: onFavoriteTap,
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Route details
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.location_on,
                      label: route.startPoint ?? 'N/A',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.location_on,
                      label: route.endPoint ?? 'N/A',
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Additional info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoItem(
                    icon: Icons.access_time,
                    text: route.getOperatingHours(),
                  ),
                  _InfoItem(
                    icon: Icons.schedule,
                    text: route.getTripDurationFormatted(),
                  ),
                  _InfoItem(
                    icon: Icons.attach_money,
                    text: route.getPriceFormatted(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// Trang chi tiết tuyến xe
class BusRouteDetailPage extends StatelessWidget {
  final BusRouteModel route;

  const BusRouteDetailPage({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tuyến ${route.routeNumber}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với ảnh
            if (route.imageUrl != null)
              Image.network(
                route.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.directions_bus, size: 80),
                  );
                },
              )
            else
              Container(
                height: 200,
                color: Colors.blue.shade100,
                child: Center(
                  child: Icon(
                    Icons.directions_bus,
                    size: 80,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route number & name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          route.routeNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          route.routeName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (route.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      route.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Thông tin chi tiết
                  _DetailRow(
                    icon: Icons.location_on,
                    label: 'Điểm đầu',
                    value: route.startPoint ?? 'Chưa cập nhật',
                    color: Colors.green,
                  ),
                  _DetailRow(
                    icon: Icons.location_on,
                    label: 'Điểm cuối',
                    value: route.endPoint ?? 'Chưa cập nhật',
                    color: Colors.red,
                  ),
                  _DetailRow(
                    icon: Icons.access_time,
                    label: 'Giờ hoạt động',
                    value: route.getOperatingHours(),
                    color: Colors.blue,
                  ),
                  _DetailRow(
                    icon: Icons.schedule,
                    label: 'Thời gian di chuyển',
                    value: route.getTripDurationFormatted(),
                    color: Colors.orange,
                  ),
                  _DetailRow(
                    icon: Icons.attach_money,
                    label: 'Giá vé',
                    value: route.getPriceFormatted(),
                    color: Colors.purple,
                  ),

                  // Các điểm dừng
                  if (route.stops != null && route.stops!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Các điểm dừng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...route.stops!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stop = entry.value;
                      final isFirst = index == 0;
                      final isLast = index == route.stops!.length - 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isFirst
                                        ? Colors.green
                                        : isLast
                                            ? Colors.red
                                            : Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 30,
                                    color: Colors.grey.shade300,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  stop,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
