import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/feedback_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/feedback_model.dart';
import 'create_feedback_screen.dart';
import 'my_feedbacks_screen.dart';

class PublicFeedbacksScreen extends StatefulWidget {
  const PublicFeedbacksScreen({Key? key}) : super(key: key);

  @override
  State<PublicFeedbacksScreen> createState() => _PublicFeedbacksScreenState();
}

class _PublicFeedbacksScreenState extends State<PublicFeedbacksScreen> {
  List<FeedbackModel> _feedbacks = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;
  String? _selectedCategory;
  String? _selectedStatus;
  UserModel? _currentUser; // ✅ THÊM

  final List<String> _categories = [
    'Tất cả',
    'Giao thông',
    'Môi trường',
    'Hạ tầng',
    'An ninh',
    'Y tế',
    'Giáo dục',
    'Khác',
  ];

  final Map<String, String> _statuses = {
    'Tất cả': '',
    'Chờ xử lý': 'Pending',
    'Đang xử lý': 'Processing',
    'Đã giải quyết': 'Resolved',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); // ✅ THÊM
    _loadFeedbacks();
  }

  // ✅ THÊM: Load current user từ SharedPreferences
  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      print('❌ Error loading current user: $e');
    }
  }

  Future<void> _loadFeedbacks({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _currentPage = 1;
        _feedbacks = [];
      });
    }

    try {
      final result = await FeedbackService.getPublicFeedbacks(
        page: _currentPage,
        pageSize: 20,
        category: _selectedCategory == 'Tất cả' ? null : _selectedCategory,
        status: _selectedStatus,
      );

      if (result['success']) {
        final newFeedbacks = (result['data'] as List)
            .map((json) => FeedbackModel.fromJson(json))
            .toList();

        setState(() {
          if (loadMore) {
            _feedbacks.addAll(newFeedbacks);
          } else {
            _feedbacks = newFeedbacks;
          }
          _isLoading = false;
          _hasMore = newFeedbacks.length == 20;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ SỬA: Navigate to Create Feedback
  Future<void> _navigateToCreateFeedback() async {
    // ✅ Kiểm tra user có tồn tại không
    if (_currentUser == null) {
      // Thử load lại user
      await _loadCurrentUser();

      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Vui lòng đăng nhập để gửi phản ánh'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateFeedbackScreen(
          user: _currentUser!, // ✅ THÊM ! để assert non-null
        ),
      ),
    );

    if (result == true) {
      _loadFeedbacks();
    }
  }

  // ✅ SỬA: Navigate to My Feedbacks
  Future<void> _navigateToMyFeedbacks() async {
    // ✅ Kiểm tra user có tồn tại không
    if (_currentUser == null) {
      await _loadCurrentUser();

      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Vui lòng đăng nhập để xem phản ánh của bạn'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyFeedbacksScreen(
          user: _currentUser!, // ✅ Truyền _currentUser
        ),
      ),
    );

    if (result == true) {
      _loadFeedbacks();
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc phản ánh'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Danh mục:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category ||
                      (_selectedCategory == null && category == 'Tất cả');
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory =
                            category == 'Tất cả' ? null : category;
                      });
                      Navigator.pop(context);
                      _loadFeedbacks();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Trạng thái:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _statuses.keys.map((status) {
                  final isSelected = _selectedStatus == _statuses[status] ||
                      (_selectedStatus == null && status == 'Tất cả');
                  return FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = _statuses[status];
                      });
                      Navigator.pop(context);
                      _loadFeedbacks();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _selectedStatus = null;
              });
              Navigator.pop(context);
              _loadFeedbacks();
            },
            child: const Text('Đặt lại'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phản ánh cộng đồng'),
        elevation: 0,
        actions: [
          // ✅ Nút My Feedbacks
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.person),
                if (_currentUser != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Phản ánh của tôi',
            onPressed: _navigateToMyFeedbacks,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Lọc',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading && _feedbacks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && _feedbacks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_errorMessage),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadFeedbacks,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _feedbacks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox,
                              size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có phản ánh nào',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _navigateToCreateFeedback,
                            icon: const Icon(Icons.add),
                            label: const Text('Gửi phản ánh đầu tiên'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Info banner
                        if (_currentUser != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Xin chào ${_currentUser!.fullName ?? _currentUser!.email}! Nhấn biểu tượng người để xem phản ánh của bạn.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              await _loadCurrentUser();
                              await _loadFeedbacks();
                            },
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _feedbacks.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _feedbacks.length) {
                                  _currentPage++;
                                  _loadFeedbacks(loadMore: true);
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final feedback = _feedbacks[index];
                                return _PublicFeedbackCard(feedback: feedback);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateFeedback,
        icon: const Icon(Icons.add),
        label: const Text('Gửi phản ánh'),
      ),
    );
  }
}

class _PublicFeedbackCard extends StatelessWidget {
  final FeedbackModel feedback;

  const _PublicFeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showFeedbackDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với avatar và tên user
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      feedback.user?.getDisplayName()[0].toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback.user?.getDisplayName() ?? 'Người dùng',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(feedback.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: feedback.getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: feedback.getStatusColor()),
                    ),
                    child: Text(
                      feedback.getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: feedback.getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title và Category
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      feedback.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feedback.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                feedback.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),

              // ✅ THÊM: Image preview
              if (feedback.imageUrl != null &&
                  feedback.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    feedback.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              size: 48, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Location
              if (feedback.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        feedback.location!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Admin Response Preview
              if (feedback.adminResponse != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.reply, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Admin đã phản hồi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // User info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        feedback.user?.getDisplayName()[0].toUpperCase() ?? 'U',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feedback.user?.getDisplayName() ?? 'Người dùng',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(feedback.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: feedback.getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: feedback.getStatusColor()),
                      ),
                      child: Text(
                        feedback.getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: feedback.getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  feedback.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Details
                _DetailRow(
                  icon: Icons.category,
                  label: 'Danh mục',
                  value: feedback.category,
                ),
                if (feedback.location != null)
                  _DetailRow(
                    icon: Icons.location_on,
                    label: 'Vị trí',
                    value: feedback.location!,
                  ),
                const Divider(height: 32),

                // Description
                const Text(
                  'Mô tả chi tiết',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  feedback.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),

                // ✅ THÊM
                if (feedback.imageUrl != null &&
                    feedback.imageUrl!.isNotEmpty) ...[
                  const Divider(height: 32),
                  const Text(
                    'Hình ảnh',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      feedback.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],

                // Admin Response
                if (feedback.adminResponse != null) ...[
                  const Divider(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.admin_panel_settings,
                                color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Phản hồi từ Admin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          feedback.adminResponse!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                        if (feedback.resolvedAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Giải quyết lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(feedback.resolvedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
