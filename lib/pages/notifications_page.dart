import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications =
        await NotificationService.instance.getStoredNotifications();
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa tất cả'),
                    content: const Text('Xóa tất cả thông báo?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await NotificationService.instance.clearAll();
                  _loadNotifications();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo nào',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['read'] as bool? ?? false;
    final timestamp = DateTime.parse(notification['timestamp'] as String);
    final timeAgo = _formatTimeAgo(timestamp);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getNotificationColor(notification['data']).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getNotificationIcon(notification['data']),
          color: _getNotificationColor(notification['data']),
        ),
      ),
      title: Text(
        notification['title'] as String? ?? 'Thông báo',
        style: TextStyle(
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification['body'] as String? ?? ''),
          const SizedBox(height: 4),
          Text(
            timeAgo,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      trailing: !isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () {
        if (!isRead) {
          NotificationService.instance.markAsRead(notification['id'] as String);
          setState(() => notification['read'] = true);
        }
        _handleNotificationTap(notification['data'] as Map<String, dynamic>?);
      },
    );
  }

  IconData _getNotificationIcon(Map<String, dynamic>? data) {
    final type = data?['type'] as String?;
    switch (type) {
      case 'event':
        return Icons.event;
      case 'feedback':
        return Icons.check_circle;
      case 'flood':
        return Icons.water_drop;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(Map<String, dynamic>? data) {
    final type = data?['type'] as String?;
    switch (type) {
      case 'event':
        return Colors.purple;
      case 'feedback':
        return Colors.green;
      case 'flood':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inHours < 1) return '${difference.inMinutes} phút trước';
    if (difference.inDays < 1) return '${difference.inHours} giờ trước';
    if (difference.inDays < 7) return '${difference.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
  }

  void _handleNotificationTap(Map<String, dynamic>? data) {
    if (data == null) return;

    final type = data['type'] as String?;
    // TODO: Navigate to appropriate screen
    debugPrint('Navigate to: $type');
  }
}
