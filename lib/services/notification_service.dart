import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../pages/all_flood_reports_page.dart';
import '../pages/public_feedback_screen.dart';

// ✅ THÊM: GlobalKey cho navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ HANDLER CHO BACKGROUND MESSAGES
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message: ${message.messageId}');
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  static String get baseUrl => ApiConfig.notificationsUrl;
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ✅ KHỞI TẠO
  Future<void> initialize() async {
    debugPrint('🔔 Initializing Notification Service...');

    try {
      // 1. Request permission
      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔔 Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 2. Get FCM token
        final token = await _fcm.getToken();
        debugPrint('🔑 FCM Token: $token');

        // Save token to backend
        await _saveTokenToBackend(token);

        // 3. Initialize local notifications
        await _initLocalNotifications();

        // 4. Setup message handlers
        _setupMessageHandlers();

        // 5. Listen to token refresh
        _fcm.onTokenRefresh.listen(_saveTokenToBackend);

        debugPrint('✅ Notification Service initialized');
      } else {
        debugPrint('❌ Notification permission denied');
      }
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  // ✅ CẤU HÌNH LOCAL NOTIFICATIONS
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // ✅ TẠO NOTIFICATION CHANNEL (Android)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'smartcity_notifications', // id
      'SmartCity Notifications', // name
      description: 'Thông báo từ SmartCity',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('✅ Local notifications initialized');
  }

  // ✅ XỬ LÝ KHI NHẤN VÀO NOTIFICATION
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('👆 Notification tapped: ${response.payload}');

    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _navigateToScreen(data);
    }
  }

  // ✅ SỬA: Điều hướng không cần context
  void _navigateToScreen(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final context = navigatorKey.currentContext;

    if (context == null) {
      debugPrint('⚠️ Navigator context is null');
      return;
    }

    debugPrint('📱 Navigate to: $type');

    switch (type) {
      case 'event':
        // TODO: Navigate to event detail
        break;

      case 'flood_report':
        final reportId = data['reportId'];
        // ✅ SỬA: Bỏ required parameter 'user'
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AllFloodReportsPage(),
          ),
        );
        break;

      case 'feedback':
        final feedbackId = data['feedbackId'];
        // ✅ SỬA: Bỏ required parameter 'user' và 'feedbackId'
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PublicFeedbacksScreen(),
          ),
        );
        break;

      default:
        // Navigate to notifications page
        break;
    }
  }

  // ✅ SETUP MESSAGE HANDLERS
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📥 Foreground message: ${message.notification?.title}');
      showNotification(message);
    });

    // Background messages (app in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 App opened from notification');
      _handleMessageClick(message);
    });

    // Background handler (app terminated)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Check initial message (app opened from terminated state)
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📱 App opened from terminated state');
        _handleMessageClick(message);
      }
    });
  }

  // ✅ SỬA: Bỏ parameter navigatorKey
  void _handleMessageClick(RemoteMessage message) {
    final data = message.data;
    _navigateToScreen(data);
  }

  // ✅ HIỂN THỊ LOCAL NOTIFICATION
  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'smartcity_notifications',
      'SmartCity Notifications',
      channelDescription: 'Thông báo từ SmartCity',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      showWhen: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: data.isNotEmpty ? jsonEncode(data) : null,
    );

    // Save to local storage
    await _saveNotificationToStorage(message);
  }

  // ✅ PUBLIC METHOD
  Future<void> saveTokenToBackend(String? token) async {
    await _saveTokenToBackend(token);
  }

  // ✅ PRIVATE METHOD
  Future<void> _saveTokenToBackend(String? token) async {
    if (token == null) {
      debugPrint('⚠️ FCM Token is null');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      // ✅ LẤY JWT TOKEN
      final jwtToken = prefs.getString('token') ?? prefs.getString('jwt_token');

      if (jwtToken == null) {
        debugPrint('⚠️ No JWT token found');
        return;
      }

      final url = '${ApiConfig.baseUrl}/api/Auth/fcm-token';
      debugPrint('📤 Sending FCM token to: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({'fcmToken': token}),
      );

      debugPrint('📥 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token saved successfully');
      } else {
        debugPrint('❌ Failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }

  // ✅ LƯU NOTIFICATION VÀO LOCAL STORAGE
  Future<void> _saveNotificationToStorage(RemoteMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('notifications') ?? [];

    final notificationData = jsonEncode({
      'id':
          message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    });

    notifications.insert(0, notificationData);

    if (notifications.length > 50) {
      notifications.removeRange(50, notifications.length);
    }

    await prefs.setStringList('notifications', notifications);
    debugPrint('💾 Saved notification');
  }

  // ✅ LẤY DANH SÁCH NOTIFICATIONS TỪ LOCAL
  Future<List<Map<String, dynamic>>> getStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('notifications') ?? [];

    return notifications
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
  }

  // ✅ ĐÁNH DẤU ĐÃ ĐỌC
  Future<void> markAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('notifications') ?? [];

    final updatedNotifications = notifications.map((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      if (data['id'] == notificationId) {
        data['read'] = true;
      }
      return jsonEncode(data);
    }).toList();

    await prefs.setStringList('notifications', updatedNotifications);
  }

  // ✅ XÓA TẤT CẢ NOTIFICATIONS
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
    await _localNotifications.cancelAll();
    debugPrint('🗑️ Cleared all');
  }
}
