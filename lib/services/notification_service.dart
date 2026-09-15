import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotificationService {
  // Lấy danh sách ID thông báo đã đọc từ Local Storage theo User
  static Future<Set<String>> getReadIds(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList('read_noti_$userId') ?? [];
    return list.toSet();
  }

  // Lưu 1 ID đã đọc
  static Future<void> markAsRead(String userId, String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final readSet = await getReadIds(userId);
    readSet.add(notificationId);
    await prefs.setStringList('read_noti_$userId', readSet.toList());
  }

  // Đánh dấu tất cả là đã đọc
  static Future<void> markAllAsRead(String userId, List<String> allIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_noti_$userId', allIds);
  }

  // TỔNG HỢP THÔNG BÁO TỪ DỮ LIỆU THỰC
  static Future<List<Map<String, dynamic>>> fetchNotifications(String userId, Map<String, dynamic>? userProfile) async {
    List<Map<String, dynamic>> rawList = [];
    final readIds = await getReadIds(userId);

    // 1. Tạo thông báo Cập nhật tài khoản (nếu có thông tin profile)
    if (userProfile != null) {
      final notiId = 'profile_update_$userId';
      rawList.add({
        'id': notiId,
        'title': 'Cập nhật tài khoản thành công',
        'message': 'Thông tin cá nhân của bạn đã được ghi nhận trên hệ thống.',
        'time': 'Tài khoản',
        'type': 'account',
        'isRead': readIds.contains(notiId),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    // 2. Tạo thông báo từ Danh sách Đơn hàng (API)
    try {
      final orders = await ApiService.getOrdersByUserId(int.parse(userId));
      for (var order in orders) {
        final orderId = order['ORDERID'] ?? order['OrderID'] ?? order['id'] ?? '';
        final status = (order['STATUS'] ?? order['Status'] ?? '').toString().toLowerCase();
        final rawDate = order['ORDERDATE'] ?? order['OrderDate'] ?? '';

        String title = '';
        String message = '';
        String type = 'order_success';

        if (status == 'pending' || status == 'chờ xác nhận') {
          title = 'Đặt hàng thành công';
          message = 'Đơn hàng #$orderId của bạn đã được khởi tạo thành công.';
          type = 'order_success';
        } else if (status == 'shipping' || status == 'delivering' || status == 'đang giao') {
          title = 'Cập nhật trạng thái đơn hàng';
          message = 'Đơn hàng #$orderId đã chuyển sang trạng thái "Đang giao".';
          type = 'order_status';
        } else if (status == 'completed' || status == 'delivered' || status == 'đã giao') {
          title = 'Đơn hàng hoàn tất';
          message = 'Đơn hàng #$orderId đã giao thành công. Cảm ơn bạn đã mua hàng!';
          type = 'order_status';
        }

        if (title.isNotEmpty) {
          final notiId = 'order_${orderId}_$status';
          rawList.add({
            'id': notiId,
            'title': title,
            'message': message,
            'time': rawDate.length >= 10 ? rawDate.substring(0, 10) : 'Gần đây',
            'type': type,
            'isRead': readIds.contains(notiId),
            'timestamp': DateTime.tryParse(rawDate)?.millisecondsSinceEpoch ?? 0,
          });
        }
      }
    } catch (_) {}

    // Sắp xếp thông báo mới nhất lên đầu
    rawList.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

    return rawList;
  }
}