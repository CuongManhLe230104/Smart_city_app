// File: lib/auth/pages/tour_detail_page.dart

import 'package:flutter/material.dart';
import '../models/travel_tour_model.dart';
import '../services/tour_service.dart';

class TourDetailPage extends StatefulWidget {
  final TravelTour tour;
  const TourDetailPage({super.key, required this.tour});

  @override
  State<TourDetailPage> createState() => _TourDetailPageState();
}

class _TourDetailPageState extends State<TourDetailPage> {
  final _peopleController = TextEditingController(text: '1');
  final _requestsController = TextEditingController();
  DateTime? _selectedTravelDate;
  bool _isProcessing = false;
  double _estimatedTotalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _calculatePrice();
    _peopleController.addListener(_calculatePrice);
  }

  @override
  void dispose() {
    _peopleController.removeListener(_calculatePrice);
    _peopleController.dispose();
    _requestsController.dispose();
    super.dispose();
  }

  void _calculatePrice() {
    final people = int.tryParse(_peopleController.text) ?? 0;
    setState(() {
      if (people > 0 && people <= widget.tour.maxPeople) {
        _estimatedTotalPrice = people * widget.tour.price;
      } else {
        _estimatedTotalPrice = 0.0;
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2028),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.pink,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTravelDate = picked;
      });
    }
  }

  Future<void> _createBooking() async {
    if (_isProcessing) return;

    // ✅ CHECK AUTH FIRST
    final authStatus = await TourService.debugAuthStatus();
    debugPrint('🔍 Auth status before booking: $authStatus');

    if (!authStatus['hasToken']) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Yêu cầu đăng nhập'),
          content: const Text(
              'Bạn cần đăng nhập để đặt tour. Chuyển đến trang đăng nhập?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      );
      return;
    }

    final people = int.tryParse(_peopleController.text) ?? 0;

    if (people <= 0 || _selectedTravelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập số người và chọn ngày đi hợp lệ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (people > widget.tour.maxPeople) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '❌ Số lượng người vượt quá giới hạn (${widget.tour.maxPeople})'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await TourService.createBooking(
        tourId: widget.tour.id,
        numberOfPeople: people,
        travelDate: _selectedTravelDate!,
        specialRequests: _requestsController.text.isNotEmpty
            ? _requestsController.text
            : null,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Đặt tour thành công! Tổng: ${_estimatedTotalPrice.toStringAsFixed(0)} đ'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${response['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX IMAGE URL
    final String imageUrl = (widget.tour.coverImageUrl != null &&
            widget.tour.coverImageUrl!.isNotEmpty)
        ? widget.tour.coverImageUrl!
        : 'https://via.placeholder.com/600x400/FF69B4/FFFFFF?text=${Uri.encodeComponent(widget.tour.nameTour)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tour.nameTour),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ IMAGE WITH HERO ANIMATION
                Hero(
                  tag: 'tour-${widget.tour.id}',
                  child: Image.network(
                    imageUrl,
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 280,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 280,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink.shade200,
                              Colors.purple.shade200
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.tour,
                                  color: Colors.white, size: 60),
                              const SizedBox(height: 12),
                              Text(
                                widget.tour.nameTour,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE
                      Text(
                        widget.tour.nameTour,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // DETAILS ROW
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(Icons.access_time_filled,
                              widget.tour.duration, Colors.blue),
                          _buildInfoChip(Icons.people_alt,
                              'Max ${widget.tour.maxPeople}', Colors.green),
                          _buildInfoChip(Icons.category_rounded,
                              widget.tour.tourType, Colors.orange),
                        ],
                      ),

                      const Divider(height: 32),

                      // CONTENT
                      const Text(
                        'Mô tả',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.tour.content,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                        textAlign: TextAlign.justify,
                      ),

                      const SizedBox(height: 24),

                      // TIMELINE
                      const Text(
                        'Lịch trình',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.tour.timeline,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // BOOKING FORM
                      _buildBookingForm(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // FOOTER
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2))
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Tổng cộng',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey)),
                          Text(
                            '${_estimatedTotalPrice.toStringAsFixed(0)} đ',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.pink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _createBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Đặt Ngay',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝 Thông tin đặt chỗ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // NUMBER OF PEOPLE
          TextField(
            controller: _peopleController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Số lượng người',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.people),
              errorText: (int.tryParse(_peopleController.text) ?? 0) >
                      widget.tour.maxPeople
                  ? 'Vượt quá ${widget.tour.maxPeople}'
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // DATE PICKER
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.pink),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTravelDate == null
                        ? 'Chọn ngày đi'
                        : '${_selectedTravelDate!.day}/${_selectedTravelDate!.month}/${_selectedTravelDate!.year}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedTravelDate == null
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // SPECIAL REQUESTS
          TextField(
            controller: _requestsController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Yêu cầu đặc biệt (tùy chọn)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Color {
  Color? get shade700 => null;
}
