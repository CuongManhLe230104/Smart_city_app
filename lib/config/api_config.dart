import 'dart:io' show Platform;

class ApiConfig {
  static const String _defaultIP = '192.168.1.16';

  static String get baseIP {
    if (Platform.isAndroid) {
      const envIP = String.fromEnvironment('BACKEND_IP');
      if (envIP.isNotEmpty) {
        return envIP;
      }

      return _defaultIP;
    } else if (Platform.isIOS) {
      return 'localhost';
    }
    return 'localhost';
  }

  // Base URLs
  static String get baseUrl => 'http://$baseIP:5000';
  static String get apiUrl => '$baseUrl/api';

  // Endpoints
  static String get authUrl => '$apiUrl/auth';
  static String get floodReportsUrl => '$apiUrl/floodreports';
  static String get feedbackUrl => '$apiUrl/feedback';
  static String get uploadUrl => '$apiUrl/upload';
  static String get busRoutesUrl => '$apiUrl/BusRoutes';
  static String get searchUrl => '$apiUrl/search';
  static String get eventBannersUrl => '$apiUrl/EventBanners';
  static String get locationUrl => '$apiUrl/location';
  static String get travelToursUrl => '$apiUrl/traveltours';
  static String get bookingsUrl => '$apiUrl/bookings';

  // External APIs
  static const String weatherApiKey = 'b19130f92ebc617c3b3f0d52f0178d18';
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';
  static const String mapApiKey = 'pk.775aea632346a6c8295fe849c170b94b';
  static const String mapBaseUrl = 'https://us1.locationiq.com/v1';

  // ✅ Debug info
  static void printDebugInfo() {
    print('🔧 ========================================');
    print('   ApiConfig Debug Info');
    print('========================================');
    print('   IP: $baseIP');
    print('   Base URL: $baseUrl');
    print('   Platform: ${Platform.operatingSystem}');
    print('========================================\n');
  }
}
