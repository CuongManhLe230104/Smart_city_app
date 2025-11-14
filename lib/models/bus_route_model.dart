// Model (phiên bản Dart)
class BusRouteModel {
  final int id;
  final String routeNumber;
  final String routeName;
  final String? schedule;
  final String? description;
  final String? startPoint;
  final String? endPoint;
  final double? price;
  final String? firstBusTime;
  final String? lastBusTime;
  final int? tripDuration;
  final List<String>? stops;
  final String? imageUrl;
  final bool isActive;

  BusRouteModel({
    required this.id,
    required this.routeNumber,
    required this.routeName,
    this.schedule,
    this.description,
    this.startPoint,
    this.endPoint,
    this.price,
    this.firstBusTime,
    this.lastBusTime,
    this.tripDuration,
    this.stops,
    this.imageUrl,
    required this.isActive,
  });

  // Factory constructor để parse JSON
  factory BusRouteModel.fromJson(Map<String, dynamic> json) {
    return BusRouteModel(
      id: json['id'],
      routeNumber: json['routeNumber'],
      routeName: json['routeName'],
      schedule: json['schedule'],
      description: json['description'],
      startPoint: json['startPoint'],
      endPoint: json['endPoint'],
      price: json['price']?.toDouble(),
      firstBusTime: json['firstBusTime'],
      lastBusTime: json['lastBusTime'],
      tripDuration: json['tripDuration'],
      stops: json['stops'] != null ? List<String>.from(json['stops']) : null,
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
    );
  }

  String getPriceFormatted() {
    if (price == null) return 'Chưa cập nhật';
    return '${price!.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}đ';
  }

  String getOperatingHours() {
    if (firstBusTime != null && lastBusTime != null) {
      return '$firstBusTime - $lastBusTime';
    }
    return 'Chưa cập nhật';
  }

  String getTripDurationFormatted() {
    if (tripDuration == null) return 'Chưa cập nhật';
    if (tripDuration! < 60) return '$tripDuration phút';
    final hours = tripDuration! ~/ 60;
    final minutes = tripDuration! % 60;
    return minutes > 0 ? '${hours}h ${minutes}p' : '${hours}h';
  }
}
