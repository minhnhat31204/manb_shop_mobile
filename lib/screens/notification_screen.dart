import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Sửa giao diện NotificationScreen để tự làm mới dữ liệu
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadNotifications(); // Tự động load lại mỗi khi màn hình active/thay đổi state
  }

  Future<void> _loadNotifications() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.currentUserId?.toString();

    if (userId == null || userId.isEmpty) {
      setState(() => _notifications = []);
      return;
    }

    setState(() => _isLoading = true);
    final list = await NotificationService.fetchNotifications(
      userId,
      userProvider.user,
    );
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  Widget _buildNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case 'account':
        iconData = Icons.person_rounded;
        iconColor = const Color(0xFF2563EB);
        bgColor = const Color(0xFFEFF6FF);
        break;
      case 'order_success':
        iconData = Icons.shopping_bag_rounded;
        iconColor = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        break;
      case 'order_status':
        iconData = Icons.local_shipping_rounded;
        iconColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFFFBEB);
        break;
      default:
        iconData = Icons.notifications_rounded;
        iconColor = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFF5F3FF);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }

  Future<void> _markAsRead(String notiId) async {
    final userId = Provider.of<UserProvider>(
      context,
      listen: false,
    ).currentUserId?.toString();
    if (userId == null) return;

    await NotificationService.markAsRead(userId, notiId);
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == notiId);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
      }
    });
  }

  Future<void> _markAllAsRead() async {
    final userId = Provider.of<UserProvider>(
      context,
      listen: false,
    ).currentUserId?.toString();
    if (userId == null) return;

    final allIds = _notifications.map((n) => n['id'].toString()).toList();
    await NotificationService.markAllAsRead(userId, allIds);
    setState(() {
      for (var item in _notifications) {
        item['isRead'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context).currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Thông báo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          if (userId != null && _notifications.isNotEmpty)
            IconButton(
              tooltip: 'Đánh dấu tất cả đã đọc',
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: userId == null
          ? const Center(
              child: Text(
                'Vui lòng đăng nhập để xem thông báo',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          : _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
            )
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  final bool isRead = item['isRead'] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isRead
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFFBAE6FD),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _markAsRead(item['id']),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNotificationIcon(item['type']),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['title'],
                                            style: TextStyle(
                                              fontWeight: isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.bold,
                                              fontSize: 14,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF1E40AF),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['message'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['time'],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
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
                },
              ),
            ),
    );
  }
}
