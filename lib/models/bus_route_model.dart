// Model (phiên bản Dart)
class BusRouteModel {
  final int id;
  final String routeNumber;
  final String routeName;
  final String? schedule;

  BusRouteModel({
    required this.id,
    required this.routeNumber,
    required this.routeName,
    this.schedule,
  });

  // Factory constructor để parse JSON
  factory BusRouteModel.fromJson(Map<String, dynamic> json) {
    return BusRouteModel(
      id: json['id'],
      routeNumber: json['routeNumber'],
      routeName: json['routeName'],
      schedule: json['schedule'],
    );
  }
}
