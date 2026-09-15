import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  //IP máy tính chạy server Node.js của bạn
  static const String baseUrl = 'http://192.168.154.1:5000/api';

  // 1. Lưu người dùng mới vào Database
  static Future<http.Response> registerUser(Map<String, dynamic> userData) async {
    // Đổi /register thành /auth/register cho đúng với route Backend
    final url = Uri.parse('$baseUrl/auth/register'); 
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
  }

  // 2. Lấy thông tin user bằng số điện thoại (cho luồng đăng nhập OTP)
  static Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      // Thay đổi URL API cho đúng với Backend của bạn
      final url = Uri.parse('$baseUrl/users/by-phone/$phone'); 
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Lỗi gọi API getUserByPhone: $e');
    }
    return null;
  }

  static Future<http.Response> checkUserByPhone(String phone) async {
    final url = Uri.parse('$baseUrl/users/check-phone'); // Điều chỉnh endpoint cho đúng với route backend của bạn
    
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

  // Lấy danh sách Categories
  static Future<http.Response> getCategories() {
    return http.get(Uri.parse('$baseUrl/categories'));
  }

  // 1. Tạo đơn hàng
  static Future<http.Response> createOrder(Map<String, dynamic> orderData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(orderData),
    );
    return response;
  }

  // 2. Lấy danh sách đơn hàng theo UserId
  static Future<List<dynamic>> getOrdersByUserId(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/orders/user/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // 3. Lấy danh sách sản phẩm yêu thích
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

  // Kiểm tra quyền được đánh giá sản phẩm
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

  // Lấy danh sách bình luận của sản phẩm
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

  // Gửi đánh giá mới
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

  // 1. Sửa URL lấy bình luận theo đúng route của Server (/reviews/product/:productId)
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

  // 2. Sửa Key của JSON payload gửi lên cho khớp với Server (Viết hoa chữ cái đầu)
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
    final url = Uri.parse('$baseUrl/promotions'); // Đường dẫn API promotions của bạn
    return await http.get(url);
  }
}