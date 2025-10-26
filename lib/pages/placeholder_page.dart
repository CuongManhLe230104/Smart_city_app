// lib/pages/placeholder_page.dart
import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Đây là trang $title',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
