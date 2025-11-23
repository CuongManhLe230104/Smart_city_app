import 'package:flutter/material.dart';

class FloodReportModel {
  final int id;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final String? address;
  final String imageUrl;
  final String waterLevel;
  final String status;
  final String? adminNote;
  final int userId;
  final String? userName;
  final DateTime createdAt;
  final DateTime? approvedAt;

  FloodReportModel({
    required this.id,
    required this.title,
    this.description,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.imageUrl,
    required this.waterLevel,
    required this.status,
    this.adminNote,
    required this.userId,
    this.userName, // ✅ Thêm vào constructor
    required this.createdAt,
    this.approvedAt,
  });

  factory FloodReportModel.fromJson(Map<String, dynamic> json) {
    return FloodReportModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'],
      imageUrl: json['imageUrl'] ?? '',
      waterLevel: json['waterLevel'] ?? 'Unknown',
      status: json['status'] ?? 'Pending',
      adminNote: json['adminNote'],
      userId: json['userId'] ?? json['user']?['id'] ?? 0,
      userName: json['user']?['fullName'] ??
          json['userName'], // ✅ Parse userName từ JSON
      createdAt: DateTime.parse(json['createdAt']),
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'imageUrl': imageUrl,
      'waterLevel': waterLevel,
      'status': status,
      'adminNote': adminNote,
      'userId': userId,
      'userName': userName, // ✅ Thêm vào JSON
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }

  Color getWaterLevelColor() {
    switch (waterLevel) {
      case 'Low':
        return Colors.yellow;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Dangerous':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String getWaterLevelText() {
    switch (waterLevel) {
      case 'Low':
        return 'Thấp';
      case 'Medium':
        return 'Trung bình';
      case 'High':
        return 'Cao';
      case 'Dangerous':
        return 'Nguy hiểm';
      default:
        return 'Không rõ';
    }
  }
}
