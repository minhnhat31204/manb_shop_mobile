import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // IP máy tính chạy server Node.js của bạn
  static const String baseUrl = 'http://192.168.154.1:5000/api';

  // 1. Đăng nhập
  static Future<http.Response> login(Map<String, dynamic> credentials) async {
    final url = Uri.parse('$baseUrl/auth/login');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(credentials),
    );
  }

  // 2. Gửi OTP Đăng ký (MỚI BỔ SUNG)
  static Future<http.Response> sendRegistrationOtp(String phone) async {
    final url = Uri.parse('$baseUrl/auth/register/send-otp');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
  }

  // 3. Lưu người dùng mới vào Database (Đăng ký)
  static Future<http.Response> registerUser(Map<String, dynamic> userData) async {
    final url = Uri.parse('$baseUrl/auth/register'); 
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
  }

  // 4. Gửi mã OTP khôi phục mật khẩu (SỬA LẠI ĐÚNG ROUTE BACKEND)
  static Future<http.Response> sendPasswordResetOtp(String email) async {
    final url = Uri.parse('$baseUrl/auth/forgot-password/send-otp');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'channel': 'email', 'email': email}),
    );
  }

  // 5. Xác thực mã OTP khôi phục mật khẩu (SỬA LẠI ĐÚNG ROUTE BACKEND)
  static Future<http.Response> verifyPasswordResetOtp(String email, String otp) async {
    final url = Uri.parse('$baseUrl/auth/forgot-password/verify-otp');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'channel': 'email', 'email': email, 'otp': otp}),
    );
  }

  // 6. Đặt lại mật khẩu mới (SỬA LẠI ĐÚNG ROUTE BACKEND)
  static Future<http.Response> resetPassword(String email, String newPassword) async {
    final url = Uri.parse('$baseUrl/auth/forgot-password/reset');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'channel': 'email', 'email': email, 'newPassword': newPassword}),
    );
  }

  // Lấy danh sách tin công nghệ từ API
  static Future<http.Response> getTechNews() async {
    final url = Uri.parse('$baseUrl/news'); 
    return await http.get(url);
  }

  // Lấy thông tin user bằng số điện thoại
  static Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      final url = Uri.parse('$baseUrl/users/by-phone/$phone'); 
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi gọi API getUserByPhone: $e');
    }
    return null;
  }

  static Future<http.Response> checkUserByPhone(String phone) async {
    final url = Uri.parse('$baseUrl/users/check-phone');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
  }

  static Future<List<dynamic>> fetchFavorites(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/favorites/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<bool> toggleFavoriteApi(int userId, int productId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'productId': productId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<http.Response> getProducts() {
    return http.get(Uri.parse('$baseUrl/products'));
  }

  static Future<http.Response> getCategories() {
    return http.get(Uri.parse('$baseUrl/categories'));
  }

  static Future<http.Response> createOrder(Map<String, dynamic> orderData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(orderData),
    );
    return response;
  }

  static Future<List<dynamic>> getOrdersByUserId(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/orders/user/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<List<dynamic>> getFavorites(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/favorites/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<bool> addFavorite(dynamic userId, dynamic productId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/favorites'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'UserID': userId,
        'ProductID': productId,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> removeFavorite(dynamic userId, dynamic productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/favorites?userId=$userId&productId=$productId'),
    );
    return response.statusCode == 200;
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  static Future<bool> checkCanReview(int orderId, int productId, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/check-eligibility?orderId=$orderId&productId=$productId&userId=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['canReview'] ?? false;
      }
    } catch (e) {
      debugPrint("Lỗi check review: $e");
    }
    return false;
  }

  static Future<List<dynamic>> getProductReviews(int productId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/reviews/product/$productId'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint("Lỗi getProductReviews: $e");
    }
    return [];
  }

  static Future<bool> postReview(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint("Lỗi postReview: $e");
    }
    return false;
  }

  static Future<List<dynamic>> getReviewsByProductId(dynamic productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/product/$productId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi tải đánh giá: $e');
    }
    return [];
  }

  static Future<bool> submitReview({
    required int orderId,
    required int productId,
    required int userId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'OrderID': orderId,
          'ProductID': productId,
          'UserID': userId,
          'Rating': rating,
          'Comment': comment,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Lỗi submitReview: $e");
      return false;
    }
  }

  static Future<http.Response> googleLogin({
    required String fullName,
    required String email,
    required String avatar,
  }) async {
    final url = Uri.parse('$baseUrl/auth/google-login');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'avatar': avatar,
      }),
    );
  }

  static Future<http.Response> getPromotions() async {
    final url = Uri.parse('$baseUrl/promotions');
    return await http.get(url);
  }

  // =========================
  // SUPPORT / CHAT
  // =========================

  static Future<http.Response> openSupportConversation({
    int? userId,
    String? visitorKey,
    String? name,
    String? email,
  }) async {
    final url = Uri.parse('$baseUrl/support/conversations/open');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (userId != null && userId > 0) 'userId': userId,
        if (visitorKey != null && visitorKey.isNotEmpty) 'visitorKey': visitorKey,
        'name': name ?? 'Khách hàng',
        if (email != null && email.isNotEmpty) 'email': email,
      }),
    );
  }

  static Future<http.Response> getSupportMessages(
    int conversationId, {
    String? role,
    int? userId,
    String? visitorKey,
  }) async {
    final Map<String, String> queryParams = {};
    if (role != null && role.isNotEmpty) queryParams['role'] = role;
    if (userId != null && userId > 0) queryParams['userId'] = userId.toString();
    if (visitorKey != null && visitorKey.isNotEmpty) queryParams['visitorKey'] = visitorKey;

    final uri = Uri.parse('$baseUrl/support/conversations/$conversationId/messages').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return await http.get(uri);
  }

  static Future<http.Response> sendSupportMessage(
    int conversationId, {
    required String message,
    String? role,
    int? userId,
    String? visitorKey,
    String? senderName,
  }) async {
    final url = Uri.parse('$baseUrl/support/conversations/$conversationId/messages');
    final Map<String, dynamic> body = {'message': message};
    if (role != null) body['role'] = role;
    if (userId != null && userId > 0) body['userId'] = userId;
    if (visitorKey != null) body['visitorKey'] = visitorKey;
    if (senderName != null) body['senderName'] = senderName;

    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> requestSupportAiReply(
    int conversationId, {
    int? userId,
    String? visitorKey,
  }) async {
    final url = Uri.parse('$baseUrl/support/conversations/$conversationId/ai-reply');
    final Map<String, dynamic> body = {};
    if (userId != null && userId > 0) body['userId'] = userId;
    if (visitorKey != null) body['visitorKey'] = visitorKey;

    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }
}