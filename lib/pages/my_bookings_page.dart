// File: lib/auth/pages/my_bookings_page.dart

import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/tour_service.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  // --- HÀM 1: LẤY LỊCH SỬ ĐẶT TOUR ---
  Future<void> _fetchBookings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await TourService.getMyBookings();

      if (response['success'] == true) {
        setState(() {
          // Sắp xếp theo ngày đặt tour mới nhất
          _bookings = (response['data'] as List<Booking>)
              .toList()
              .cast<Booking>(); // Ép kiểu an toàn hơn
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Không thể tải lịch sử đặt tour.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // --- HÀM XỬ LÝ XÁC NHẬN HỦY ---
  void _showCancelConfirmation(int bookingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Xác nhận hủy?'),
          content:
              const Text('Bạn có chắc chắn muốn hủy đơn đặt tour này không?'),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('Không', style: TextStyle(color: Colors.black54)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              // Nút hủy nổi bật
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hủy Tour'),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelBooking(bookingId);
              },
            ),
          ],
        );
      },
    );
  }

  // --- HÀM 2: GỌI API HỦY ĐẶT TOUR ---
  void _cancelBooking(int bookingId) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Đang hủy đơn hàng $bookingId...'),
      duration: const Duration(seconds: 5),
    ));

    try {
      final response = await TourService.cancelBooking(bookingId);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Hủy đơn hàng thành công.'),
            backgroundColor: Colors.green));
        _fetchBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hủy thất bại: ${response['message']}'),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi hệ thống khi hủy: ${e.toString()}'),
          backgroundColor: Colors.red));
    }
  }

  // 🆕 Hàm tiện ích để xác định màu và icon trạng thái
  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status) {
      case 'Confirmed':
        return {
          'color': Colors.green,
          'icon': Icons.check_circle_rounded,
          'text': 'ĐÃ XÁC NHẬN'
        };
      case 'Cancelled':
        return {
          'color': Colors.red,
          'icon': Icons.cancel_rounded,
          'text': 'ĐÃ HỦY'
        };
      case 'Completed':
        return {
          'color': Colors.blueGrey,
          'icon': Icons.done_all,
          'text': 'HOÀN THÀNH'
        };
      default: // Pending
        return {
          'color': Colors.orange,
          'icon': Icons.pending_actions_rounded,
          'text': 'CHỜ XỬ LÝ'
        };
    }
  }

  // 🆕 Widget xây dựng Card đặt tour hiện đại (Kiểu 2)
  Widget _buildBookingCard(Booking booking) {
    final style = _getStatusStyle(booking.status);
    final String tourNamePlaceholder =
        'Tour ID: ${booking.tourId}'; // Thay bằng tên Tour nếu có sẵn

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Thường dùng để xem chi tiết hóa đơn hoặc tour đã đặt
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER (ID & STATUS)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      tourNamePlaceholder,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: style['color'].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(style['icon'], size: 16, color: style['color']),
                        const SizedBox(width: 6),
                        Text(
                          style['text'],
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: style['color']),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // 2. CHI TIẾT ĐẶT HÀNG
              Row(
                children: [
                  const Icon(Icons.calendar_month,
                      size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Ngày khởi hành:',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const Spacer(),
                  Text(
                    '${booking.travelDate.day}/${booking.travelDate.month}/${booking.travelDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded,
                      size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Số lượng người:',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const Spacer(),
                  Text('${booking.numberOfPeople} người'),
                ],
              ),
              const SizedBox(height: 16),

              // 3. FOOTER (TỔNG TIỀN & HÀNH ĐỘNG)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tổng tiền:',
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                      Text(
                        '${booking.totalPrice.toStringAsFixed(0)} VNĐ',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.pink),
                      ),
                    ],
                  ),
                  if (booking.status == 'Pending')
                    SizedBox(
                      height: 40,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Hủy'),
                        style:
                            FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () =>
                            _showCancelConfirmation(booking.bookingId),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Sử Đặt Tour')),
      body: RefreshIndicator(
        onRefresh: _fetchBookings,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.red, size: 40),
                          const SizedBox(height: 16),
                          Text(_errorMessage!,
                              style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _fetchBookings,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _bookings.isEmpty
                    ? const Center(child: Text('Bạn chưa có đơn đặt tour nào.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          return _buildBookingCard(
                              booking); // Sử dụng Card hiện đại
                        },
                      ),
      ),
    );
  }
}
