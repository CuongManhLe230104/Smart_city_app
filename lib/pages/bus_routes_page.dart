import 'package:flutter/material.dart';
import '../models/bus_route_model.dart';
import '../services/api_service.dart';

// Trang mới để hiển thị danh sách tuyến xe buýt
class BusRoutesPage extends StatefulWidget {
  const BusRoutesPage({super.key});

  @override
  State<BusRoutesPage> createState() => _BusRoutesPageState();
}

class _BusRoutesPageState extends State<BusRoutesPage> {
  final ApiService _apiService = ApiService();
  late Future<List<BusRouteModel>> _busRoutesFuture;

  @override
  void initState() {
    super.initState();
    // Gọi API ngay khi trang được tải
    _busRoutesFuture = _apiService.fetchBusRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Các tuyến xe buýt')),
      body: FutureBuilder<List<BusRouteModel>>(
        future: _busRoutesFuture,
        builder: (context, snapshot) {
          // 1. Đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Bị lỗi
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Đã xảy ra lỗi:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // 3. Không có dữ liệu
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Không tìm thấy tuyến xe buýt nào.'),
            );
          }

          // 4. Có dữ liệu -> Hiển thị ListView
          final routes = snapshot.data!;
          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      route.routeNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(route.routeName),
                  subtitle: Text(
                    route.schedule ?? 'Không có thông tin giờ chạy',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
