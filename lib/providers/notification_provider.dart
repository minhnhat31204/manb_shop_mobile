import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  String? _currentUserId;

  List<Map<String, dynamic>> get notifications => _notifications;

  // 1. Cập nhật User ID và tự động load lại danh sách thông báo tương ứng
  void updateUserId(String? userId) {
    _currentUserId = userId;
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _notifications = [];
      notifyListeners();
    } else {
      _loadNotifications();
    }
  }

  // 2. Load thông báo từ SharedPreferences theo UserId
  Future<void> _loadNotifications() async {
    if (_currentUserId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String? rawData = prefs.getString(
      'notifications_user_$_currentUserId',
    );

    if (rawData != null && rawData.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(rawData);
      _notifications = decoded.cast<Map<String, dynamic>>();
    } else {
      _notifications = [];
    }
    notifyListeners();
  }

  // 3. Lưu danh sách thông báo hiện tại vào local
  Future<void> _saveNotifications() async {
    if (_currentUserId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_notifications);
    await prefs.setString('notifications_user_$_currentUserId', encoded);
  }

  // 4. Thêm thông báo mới (gọi từ profile, order, vnpay...)
  void addNotification({
    required String title,
    required String message,
    required String type, // 'account', 'order_success', 'order_status', 'promo'
  }) {
    if (_currentUserId == null) return;

    final newNoti = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'time': 'Vừa xong',
      'type': type,
      'isRead': false,
    };

    _notifications.insert(0, newNoti); // Đưa thông báo mới lên đầu
    _saveNotifications();
    notifyListeners();
  }

  // 5. Đánh dấu 1 thông báo đã đọc
  void markAsRead(String id) {
    final index = _notifications.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      _notifications[index]['isRead'] = true;
      _saveNotifications();
      notifyListeners();
    }
  }

  // 6. Đánh dấu tất cả đã đọc
  void markAllAsRead() {
    for (var item in _notifications) {
      item['isRead'] = true;
    }
    _saveNotifications();
    notifyListeners();
  }
}
