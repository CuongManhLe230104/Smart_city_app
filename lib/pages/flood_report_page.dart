import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';
import '../services/floodreport_service.dart';
import 'dart:async';

class FloodReportPage extends StatefulWidget {
  final UserModel user;
  const FloodReportPage({super.key, required this.user});

  @override
  State<FloodReportPage> createState() => _FloodReportPageState();
}

class _FloodReportPageState extends State<FloodReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker(); // ✅ Thêm dòng này

  File? _selectedImage;
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;
  String _waterLevel = 'Low';

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ✅ Request location permission
  Future<void> _requestLocationPermission() async {
    try {
      PermissionStatus status = await Permission.location.status;

      if (status.isDenied) {
        status = await Permission.location.request();
      }

      if (status.isPermanentlyDenied) {
        _showPermissionDialog();
      } else if (status.isGranted) {
        _getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cần quyền truy cập vị trí'),
        content: const Text(
          'Ứng dụng cần quyền truy cập vị trí để gửi báo cáo ngập lụt. '
          'Vui lòng bật quyền trong Cài đặt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );
  }

  // 📍 Lấy vị trí hiện tại
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ Kiểm tra Location Service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Vui lòng bật GPS trong Settings'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Mở Settings',
                textColor: Colors.white,
                onPressed: Geolocator.openLocationSettings,
              ),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // ✅ Kiểm tra Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Cần quyền truy cập vị trí để gửi báo cáo'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // ✅ Lấy vị trí với độ chính xác cao
      debugPrint('🔍 Đang lấy vị trí...');

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // ✅ Timeout sau 10s
      );

      debugPrint('📍 Vị trí: ${position.latitude}, ${position.longitude}');

      // ✅ Lấy địa chỉ từ tọa độ
      String address = 'Không xác định';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];

          // Format địa chỉ theo Việt Nam
          List<String> addressParts = [];

          if (place.street != null && place.street!.isNotEmpty) {
            addressParts.add(place.street!);
          }
          if (place.subAdministrativeArea != null &&
              place.subAdministrativeArea!.isNotEmpty) {
            addressParts.add(place.subAdministrativeArea!);
          }
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }

          address = addressParts.join(', ');

          if (address.isEmpty) {
            address = 'Lat: ${position.latitude.toStringAsFixed(6)}, '
                'Long: ${position.longitude.toStringAsFixed(6)}';
          }
        }
      } catch (e) {
        debugPrint('❌ Lỗi geocoding: $e');
        address = 'Lat: ${position.latitude.toStringAsFixed(6)}, '
            'Long: ${position.longitude.toStringAsFixed(6)}';
      }

      debugPrint('📍 Địa chỉ: $address');

      setState(() {
        _currentPosition = position;
        _currentAddress = address;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Đã lấy vị trí: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on TimeoutException catch (_) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Timeout: Không thể lấy vị trí. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Lỗi lấy vị trí: $e');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 📸 Chọn ảnh từ camera hoặc gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 📤 Gửi báo cáo
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng chọn ảnh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng lấy vị trí hiện tại'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Upload ảnh lên server/cloud storage
      String imageUrl =
          'https://example.com/flood-images/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FloodReportService.createFloodReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _currentAddress ?? 'Không xác định',
        imageUrl: imageUrl,
        waterLevel: _waterLevel,
        userId: widget.user.id,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Gửi báo cáo thành công! Chờ admin duyệt.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo ngập lụt'),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📸 Chọn ảnh
                    const Text(
                      'Ảnh hiện trường',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () =>
                                  setState(() => _selectedImage = null),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Chưa chọn ảnh',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Chụp ảnh'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Thư viện'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 📍 Vị trí
                    const Text(
                      'Vị trí',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Lấy vị trí hiện tại'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),

                    if (_currentPosition != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Đã có vị trí',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tọa độ: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (_currentAddress != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Địa chỉ: $_currentAddress',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 📝 Tiêu đề
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề *',
                        hintText: 'VD: Ngập nặng đường Trần Phú',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tiêu đề';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // 📝 Mô tả
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Mô tả chi tiết',
                        hintText: 'Mô tả tình trạng ngập, diện tích...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 💧 Mức nước
                    const Text(
                      'Mức độ ngập',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildWaterLevelChip('Low', 'Thấp', Colors.yellow),
                        _buildWaterLevelChip(
                            'Medium', 'Trung bình', Colors.orange),
                        _buildWaterLevelChip('High', 'Cao', Colors.red),
                        _buildWaterLevelChip(
                            'Critical', 'Nguy hiểm', Colors.purple),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 📤 Nút gửi
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submitReport,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Gửi báo cáo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWaterLevelChip(String value, String label, Color color) {
    final isSelected = _waterLevel == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _waterLevel = value;
        });
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: Color.lerp(color, Colors.black, 0.7)!,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : color.withOpacity(0.3),
        width: isSelected ? 2 : 1,
      ),
    );
  }
}
