// import 'package:flutter/material.dart';
// import 'package:smart_city/services/api_service.dart';

// class TestApiPage extends StatefulWidget {
//   const TestApiPage({super.key});

//   @override
//   State<TestApiPage> createState() => _TestApiPageState();
// }

// class _TestApiPageState extends State<TestApiPage> {
//   String result = '';

//   Future<void> _testApi() async {
//     final api = ApiService();
//     final res = await api.fetchTestPost();
//     setState(() => result = res);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Test API')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             ElevatedButton(
//               onPressed: _testApi,
//               child: const Text('Gọi API thử'),
//             ),
//             const SizedBox(height: 20),
//             Text(result),
//           ],
//         ),
//       ),
//     );
//   }
// }
