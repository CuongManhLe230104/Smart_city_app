import 'package:flutter/material.dart';
import '../services/feedback_service.dart';
import '../models/user_model.dart';

class CreateFeedbackScreen extends StatefulWidget {
  final UserModel user;

  const CreateFeedbackScreen({super.key, required this.user});

  @override
  State<CreateFeedbackScreen> createState() => _CreateFeedbackScreenState();
}

class _CreateFeedbackScreenState extends State<CreateFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'Giao thông';
  bool _isLoading = false;
  String _errorMessage = '';

  final List<String> _categories = [
    'Giao thông',
    'Môi trường',
    'Hạ tầng',
    'An ninh',
    'Y tế',
    'Giáo dục',
    'Khác',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Giao thông': Icons.directions_car,
    'Môi trường': Icons.eco,
    'Hạ tầng': Icons.construction,
    'An ninh': Icons.security,
    'Y tế': Icons.local_hospital,
    'Giáo dục': Icons.school,
    'Khác': Icons.more_horiz,
  };

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await FeedbackService.createFeedback(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        userId: widget.user.id,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Gửi phản ánh thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true); // Return true để reload list
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gửi phản ánh'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header với icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.feedback,
                        size: 64,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Phản ánh góp ý',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy cho chúng tôi biết vấn đề bạn gặp phải',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Danh mục
                const Text(
                  'Danh mục *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _categoryIcons[category],
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(category),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      selectedColor: Colors.blue.shade600,
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Tiêu đề
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề *',
                    hintText: 'VD: Đường bị hỏng, ổ gà',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tiêu đề';
                    }
                    if (value.length < 5) {
                      return 'Tiêu đề phải có ít nhất 5 ký tự';
                    }
                    return null;
                  },
                  maxLength: 200,
                ),
                const SizedBox(height: 16),

                // Mô tả
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả chi tiết *',
                    hintText: 'Mô tả chi tiết vấn đề bạn gặp phải...',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  maxLength: 1000,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mô tả';
                    }
                    if (value.length < 20) {
                      return 'Mô tả phải có ít nhất 20 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Vị trí
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Vị trí (tuỳ chọn)',
                    hintText: 'VD: Đường Lê Lợi, Vũng Tàu',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  maxLength: 200,
                ),
                const SizedBox(height: 24),

                // Nút gửi
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : FilledButton.icon(
                        onPressed: _submitFeedback,
                        icon: const Icon(Icons.send),
                        label: const Text(
                          'Gửi phản ánh',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),

                // Ghi chú
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Phản ánh của bạn sẽ được chúng tôi xem xét và phản hồi trong thời gian sớm nhất.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
