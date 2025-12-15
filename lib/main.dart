import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'models/user_model.dart';
import 'dart:convert'; // ← Thêm import này

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ KHỞI TẠO FIREBASE
  await Firebase.initializeApp();

  // ✅ KHỞI TẠO NOTIFICATION SERVICE
  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ✅ Kiểm tra xem có token không
  Future<bool> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Đọc đúng key mà bạn đã lưu trong login_screen
      final token = prefs.getString('jwt_token') ?? prefs.getString('token');

      debugPrint('🔍 Token exists: ${token != null}');

      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking login status: $e');
      return false;
    }
  }

  // ✅ Lấy user từ SharedPreferences
  Future<UserModel?> _getSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Đọc user từ JSON string đã lưu
      final userJson = prefs.getString('user');

      debugPrint('🔍 Saved user JSON: $userJson');

      if (userJson != null && userJson.isNotEmpty) {
        final userData = jsonDecode(userJson);

        return UserModel(
          id: userData['id'],
          username: userData['username'] ?? userData['email'].split('@')[0],
          email: userData['email'],
          fullName: userData['fullName'],
          phone: userData['phone'],
          address: userData['address'],
        );
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting saved user: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vũng Tàu Smart City',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Inter',
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          // ✅ Hiển thị splash screen khi đang kiểm tra
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: const Color.fromARGB(255, 159, 209, 241),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/VTSMARTCITY.png',
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Vũng Tàu Smart City',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 28, 125, 204),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Đang kiểm tra.. .',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // ✅ Có token → kiểm tra user data
          if (snapshot.data == true) {
            return FutureBuilder<UserModel?>(
              future: _getSavedUser(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    backgroundColor: const Color.fromARGB(255, 159, 209, 241),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Đang tải thông tin... '),
                        ],
                      ),
                    ),
                  );
                }

                // ✅ Có user data → vào HomePage
                if (userSnapshot.hasData && userSnapshot.data != null) {
                  debugPrint('✅ Auto-login successful');
                  return HomePage(
                    user: userSnapshot.data!,
                    eventId: null,
                  );
                }

                // ❌ Không có user data → về LoginScreen
                debugPrint(
                    '⚠️ Token exists but no user data, redirecting to login');
                return const LoginScreen();
              },
            );
          }

          // ❌ Không có token → LoginScreen
          debugPrint('⚠️ No token found, showing login screen');
          return const LoginScreen();
        },
      ),
    );
  }
}
