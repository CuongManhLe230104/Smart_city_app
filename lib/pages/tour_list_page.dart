// File: lib/auth/pages/tour_list_page.dart

import 'package:flutter/material.dart';
import '../models/travel_tour_model.dart';
import '../services/tour_service.dart';
import 'tour_detail_page.dart';

class TourListPage extends StatefulWidget {
  const TourListPage({super.key});

  @override
  State<TourListPage> createState() => _TourListPageState();
}

class _TourListPageState extends State<TourListPage> {
  List<TravelTour> _tours = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTours();
  }

  Future<void> _fetchTours() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await TourService.getAllTours();

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _tours = (response['data'] as List<TravelTour>?) ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Không thể tải danh sách tour';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Lỗi không xác định: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildTourCard(BuildContext context, TravelTour tour) {
    // ✅ FIX IMAGE URL - HANDLE NULL & EMPTY
    final String imageUrl = (tour.coverImageUrl != null &&
            tour.coverImageUrl!.isNotEmpty)
        ? tour.coverImageUrl!
        : 'https://via.placeholder.com/600x300/FF69B4/FFFFFF?text=${Uri.encodeComponent(tour.nameTour)}';

    print('🖼️ Loading image: $imageUrl');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TourDetailPage(tour: tour),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ IMAGE WITH LOADING & ERROR HANDLING
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
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
                  print('❌ Image load error for tour ${tour.id}: $error');
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade200, Colors.purple.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tour, color: Colors.white, size: 50),
                          const SizedBox(height: 8),
                          Text(
                            tour.nameTour,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
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

            // CONTENT
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.nameTour,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.category_rounded,
                          size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tour.tourType,
                          style: TextStyle(
                              color: Colors.blueGrey.shade700, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_filled,
                          size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text(
                        tour.duration,
                        style: TextStyle(
                            color: Colors.blueGrey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tour.content.length > 50
                              ? '${tour.content.substring(0, 50)}...'
                              : tour.content,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${tour.price.toStringAsFixed(0)} đ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.pink,
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchTours,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Sách Tour Du Lịch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTours,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải danh sách tour...'),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _tours.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tour,
                              size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Hiện chưa có tour nào',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _fetchTours,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tải lại'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchTours,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _tours.length,
                        itemBuilder: (context, index) {
                          return _buildTourCard(context, _tours[index]);
                        },
                      ),
                    ),
    );
  }
}
