import 'package:latlong2/latlong.dart' as latlong;

// Model để lưu kết quả tìm kiếm trả về
class LocationSearchResult {
  final latlong.LatLng coords;
  final String displayName;

  LocationSearchResult({required this.coords, required this.displayName});

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    // API LocationIQ trả về lat/lon là STRING, ta phải parse
    final double lat = double.parse(json['lat']);
    final double lon = double.parse(json['lon']);

    return LocationSearchResult(
      coords: latlong.LatLng(lat, lon),
      displayName: json['display_name'] ?? 'Không rõ tên',
    );
  }
}
