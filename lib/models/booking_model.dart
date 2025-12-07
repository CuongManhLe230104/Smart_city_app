class Booking {
  final int bookingId;
  final int userId;
  final int tourId;
  final int numberOfPeople;
  final DateTime travelDate;
  final DateTime bookingDate;
  final double totalPrice;
  final String status;
  final String? specialRequests;

  // Có thể thêm thuộc tính Tour nếu cần hiển thị chi tiết tour kèm theo
  // final TravelTour? tour;

  Booking({
    required this.bookingId,
    required this.userId,
    required this.tourId,
    required this.numberOfPeople,
    required this.travelDate,
    required this.bookingDate,
    required this.totalPrice,
    required this.status,
    this.specialRequests,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['bookingId'] as int,
      userId: json['userId'] as int,
      tourId: json['tourId'] as int,
      numberOfPeople: json['numberOfPeople'] as int,
      // Xử lý chuyển đổi chuỗi ngày thành DateTime
      travelDate: DateTime.parse(json['travelDate'] as String),
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      totalPrice: json['totalPrice'] is int
          ? (json['totalPrice'] as int).toDouble()
          : json['totalPrice'] as double,
      status: json['status'] as String,
      specialRequests: json['specialRequests'] as String?,
    );
  }
}
