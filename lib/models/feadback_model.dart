import 'package:flutter/material.dart';

class FeedbackModel {
  final int id;
  final String title;
  final String description;
  final String category;
  final String? location;
  final String? imageUrl;
  final String status;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final FeedbackUser? user; // ⭐ Thêm thông tin user

  FeedbackModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.location,
    this.imageUrl,
    required this.status,
    this.adminResponse,
    required this.createdAt,
    this.resolvedAt,
    this.user, // ⭐ Thêm
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      location: json['location'],
      imageUrl: json['imageUrl'],
      status: json['status'],
      adminResponse: json['adminResponse'],
      createdAt: DateTime.parse(json['createdAt']),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
      user: json['user'] != null
          ? FeedbackUser.fromJson(json['user'])
          : null, // ⭐ Thêm
    );
  }

  String getStatusText() {
    switch (status) {
      case 'Pending':
        return 'Chờ xử lý';
      case 'Processing':
        return 'Đang xử lý';
      case 'Resolved':
        return 'Đã giải quyết';
      case 'Rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }

  Color getStatusColor() {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ⭐ Thêm class mới
class FeedbackUser {
  final int id;
  final String? fullName;

  FeedbackUser({
    required this.id,
    this.fullName,
  });

  factory FeedbackUser.fromJson(Map<String, dynamic> json) {
    return FeedbackUser(
      id: json['id'],
      fullName: json['fullName'],
    );
  }

  String getDisplayName() {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    return 'Người dùng #$id';
  }
}
