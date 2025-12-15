// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import '../../models/user_model.dart';
// import '../../pages/home_page.dart';
// import 'login_screen.dart';
// import 'package:flutter/material.dart';

// class AuthCheckScreen extends StatefulWidget {
//   const AuthCheckScreen({super.key});

//   @override
//   State<AuthCheckScreen> createState() => _AuthCheckScreenState();
// }

// class _AuthCheckScreenState extends State<AuthCheckScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _checkLoginStatus();
//   }

//   Future<void> _checkLoginStatus() async {
//     // Đợi 1 giây để hiển thị splash (tuỳ chọn)
//     await Future.delayed(const Duration(seconds: 1));

//     try {
//       final prefs = await SharedPreferences.getInstance();

//       // Kiểm tra token
//       final token = prefs.getString('jwt_token') ?? prefs.getString('token');
//       final userJson = prefs.getString('user');

//       debugPrint('🔍 Checking auth status...');
//       debugPrint('Token exists: ${token != null}');
//       debugPrint('User data exists: ${userJson != null}');

//       if (token != null && userJson != null) {
//         // Có token và user data → tự động đăng nhập
//         debugPrint('✅ Found saved session, auto-login.. .');

//         final userData = jsonDecode(userJson);
//         final user = UserModel(
//           id: userData['id'],
//           username: userData['username'],
//           email: userData['email'],
//           fullName: userData['fullName'],
//           phone: userData['phone'],
//           address: userData['address'],
//         );

//         if (mounted) {
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(
//               builder: (context) => HomePage(
//                 user: user,
//                 eventId: null,
//               ),
//             ),
//           );
//         }
//       } else {
//         // Không có session → hiển thị LoginScreen
//         debugPrint('❌ No saved session, showing login screen');

//         if (mounted) {
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(
//               builder: (context) => const LoginScreen(),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint('❌ Error checking auth status: $e');

//       // Nếu có lỗi → hiển thị LoginScreen
//       if (mounted) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(
//             builder: (context) => const LoginScreen(),
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 159, 209, 241),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(24),
//               child: Image.asset(
//                 'assets/VTSMARTCITY.png',
//                 height: 120,
//                 fit: BoxFit.cover,
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Vũng Tàu Smart City',
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 40),
//             const CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(
//                 Color.fromARGB(255, 28, 125, 204),
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Đang kiểm tra.. .',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
