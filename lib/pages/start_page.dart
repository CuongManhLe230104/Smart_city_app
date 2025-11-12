// import 'package:flutter/material.dart';
// import '../pages/login_page.dart';

// class StartPage extends StatelessWidget {
//   const StartPage({super.key});

//   void _goToLogin(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const LoginPage()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Chào mừng')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.home, size: 80, color: Colors.blue),
//             const SizedBox(height: 20),
//             const Text(
//               'Chào mừng bạn đến với Vũng Tàu Smart city',
//               style: TextStyle(fontSize: 20),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: () => _goToLogin(context),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 15,
//                 ),
//               ),
//               child: const Text('Đăng nhập'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
