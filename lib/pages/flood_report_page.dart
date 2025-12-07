import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';
import '../services/floodreport_service.dart';
import '../services/upload_service.dart';
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
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _uploadedImageUrl;
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isGettingLocation = false;

  // ✅ THÊM: Stream để lắng nghe GPS realtime
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTrackingLocation = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    // ✅ THÊM: Tự động bật tracking khi vào page
    _startLocationTracking();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    // ✅ THÊM: Dừng tracking khi rời page
    _stopLocationTracking();
    super.dispose();
  }

  // 🔐 Kiểm tra quyền
  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;

    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }
    if (!locationStatus.isGranted) {
      await Permission.location.request();
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
          _uploadedImageUrl = null;
        });

        // Tự động upload
        await _uploadImage();
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

  // 📤 Upload ảnh lên server
  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // ✅ SỬA: uploadImage trả về String (URL), không phải Map
      final imageUrl = await UploadService.uploadFloodImage(_selectedImage!);

      setState(() {
        _uploadedImageUrl = imageUrl; // ✅ Gán trực tiếp String
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Upload ảnh thành công'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _selectedImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ THÊM: Bắt đầu theo dõi vị trí realtime
  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Dịch vụ vị trí chưa được bật';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Quyền truy cập vị trí bị từ chối';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Quyền truy cập vị trí bị từ chối vĩnh viễn';
      }

      setState(() {
        _isTrackingLocation = true;
      });

      // ✅ LẮNG NGHE VỊ TRÍ REALTIME
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Cập nhật khi di chuyển 10m
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) async {
        // ✅ TỰ ĐỘNG CẬP NHẬT VỊ TRÍ
        debugPrint(
            '📍 GPS updated: ${position.latitude}, ${position.longitude}');

        // Lấy địa chỉ mới
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          String address = 'Không xác định';
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            address =
                '${place.street}, ${place.subAdministrativeArea}, ${place.administrativeArea}';
          }

          setState(() {
            _currentPosition = position;
            _currentAddress = address;
          });
        } catch (e) {
          debugPrint('Lỗi lấy địa chỉ: $e');
          setState(() {
            _currentPosition = position;
            _currentAddress =
                'Lat: ${position.latitude.toStringAsFixed(6)}, Lon: ${position.longitude.toStringAsFixed(6)}';
          });
        }
      });

      // Lấy vị trí đầu tiên ngay lập tức
      await _getCurrentLocation();
    } catch (e) {
      debugPrint('Lỗi tracking location: $e');
      setState(() {
        _isTrackingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Không thể theo dõi vị trí: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // ✅ THÊM: Dừng theo dõi vị trí
  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    setState(() {
      _isTrackingLocation = false;
    });
    debugPrint('🛑 Stopped location tracking');
  }

  // 📍 Lấy vị trí hiện tại (giữ nguyên, dùng cho button)
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Dịch vụ vị trí chưa được bật';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Quyền truy cập vị trí bị từ chối';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Quyền truy cập vị trí bị từ chối vĩnh viễn';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = 'Không xác định';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address =
            '${place.street}, ${place.subAdministrativeArea}, ${place.administrativeArea}';
      }

      setState(() {
        _currentPosition = position;
        _currentAddress = address;
        _isGettingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lấy vị trí hiện tại'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi lấy vị trí: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 📤 Gửi báo cáo
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng chọn và upload ảnh'),
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
      final result = await FloodReportService.createFloodReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _currentAddress ?? 'Không xác định',
        imageUrl: _uploadedImageUrl!,
        waterLevel: 'Unknown', // ✅ THAY ĐỔI: Luôn gửi "Unknown"
        userId: widget.user.id,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '✅ Gửi báo cáo thành công! Chờ admin duyệt và đánh giá mức độ ngập.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
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
        actions: [
          // ✅ THÊM: Nút bật/tắt tracking
          IconButton(
            icon: Icon(
              _isTrackingLocation ? Icons.gps_fixed : Icons.gps_off,
              color: _isTrackingLocation ? Colors.green : Colors.grey,
            ),
            onPressed: () {
              if (_isTrackingLocation) {
                _stopLocationTracking();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🛑 Đã tắt theo dõi vị trí tự động'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                _startLocationTracking();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã bật theo dõi vị trí tự động'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            tooltip:
                _isTrackingLocation ? 'Tắt theo dõi GPS' : 'Bật theo dõi GPS',
          ),
        ],
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
                    // 📸 PHẦN ẢNH
                    const Text(
                      'Ảnh hiện trường *',
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

                          // Overlay upload
                          if (_isUploading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                          color: Colors.white),
                                      SizedBox(height: 12),
                                      Text(
                                        'Đang upload...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Check icon
                          if (_uploadedImageUrl != null && !_isUploading)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 24),
                              ),
                            ),

                          // Nút xóa
                          if (!_isUploading)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                    _uploadedImageUrl = null;
                                  });
                                },
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
                            Text('Chưa chọn ảnh',
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploading
                                ? null
                                : () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Chụp ảnh'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploading
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Thư viện'),
                          ),
                        ),
                      ],
                    ),

                    if (_uploadedImageUrl != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đã upload: ${_uploadedImageUrl!.split('/').last}',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 📍 VỊ TRÍ (UPDATE)
                    Row(
                      children: [
                        const Text(
                          'Vị trí *',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        // ✅ THÊM: Indicator tracking
                        if (_isTrackingLocation)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.gps_fixed,
                                    size: 14, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Đang theo dõi',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _currentPosition != null
                            ? Colors.blue.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _currentPosition != null
                              ? Colors.blue.shade200
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_currentPosition != null) ...[
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _currentAddress ?? 'Không xác định',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                              'Lon: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ] else
                            const Text(
                              'Chưa lấy vị trí',
                              style: TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _isGettingLocation ? null : _getCurrentLocation,
                        icon: _isGettingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(_isGettingLocation
                            ? 'Đang lấy vị trí...'
                            : 'Làm mới vị trí'),
                      ),
                    ),

                    // ✅ THÊM: Thông báo tracking
                    if (_isTrackingLocation) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.green.shade700, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vị trí đang được cập nhật tự động khi bạn di chuyển (mỗi 10m)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 📝 TIÊU ĐỀ
                    const Text(
                      'Tiêu đề *',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'VD: Ngập nặng đường Lê Lợi',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      maxLength: 100,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tiêu đề';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // 📄 MÔ TẢ
                    const Text(
                      'Mô tả chi tiết *',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText:
                            'Mô tả tình trạng ngập, diện tích, thời gian...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 4,
                      maxLength: 500,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập mô tả';
                        }
                        return null;
                      },
                    ),

                    // ❌ XÓA TOÀN BỘ: Phần "Mức độ ngập" (FilterChip)

                    // ✅ THÊM: Thông báo cho user
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Mức độ ngập lụt sẽ được admin đánh giá sau khi duyệt báo cáo của bạn.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            (_isLoading || _isUploading) ? null : _submitReport,
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
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
