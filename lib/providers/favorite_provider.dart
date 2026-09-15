import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FavoriteProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _favoriteProducts = [];

  List<Map<String, dynamic>> get favoriteProducts => _favoriteProducts;

  // Gọi hàm này khi ĐĂNG NHẬP thành công
  Future<void> loadFavorites(int userId) async {
    try {
      final data = await ApiService.fetchFavorites(userId);
      _favoriteProducts = List<Map<String, dynamic>>.from(
        data.map((item) {
          // Nếu API trả về dạng { "FavoriteID": 13, "ProductID": 1, "Product": { ... } }
          if (item is Map<String, dynamic> && item.containsKey('Product') && item['Product'] != null) {
            return item['Product'];
          }
          return item;
        })
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi tải danh sách yêu thích: $e');
    }
  }

  // Gọi hàm này khi ĐĂNG XUẤT
  void clearFavorites() {
    _favoriteProducts = [];
    notifyListeners();
  }

  // Hàm tiện ích: Tự động xử lý Đăng nhập / Đăng xuất
  Future<void> setUserId(int? userId) async {
    if (userId == null) {
      clearFavorites();
    } else {
      await loadFavorites(userId);
    }
  }

  // Kiểm tra sản phẩm đã nằm trong danh sách yêu thích chưa
  bool isFavorite(Map<String, dynamic> product) {
    final id = _extractProductId(product);
    if (id == null) return false;
    return _favoriteProducts.any((item) => _extractProductId(item) == id);
  }

  Future<void> toggleFavorite(Map<String, dynamic> product, dynamic userId) async {
    final intParsedUser = userId is int ? userId : int.tryParse(userId.toString());
    final intParsedProduct = _extractProductId(product);

    if (intParsedUser == null || intParsedProduct == null) {
      debugPrint('Thiếu hoặc sai kiểu dữ liệu userId/productId');
      return;
    }

    if (isFavorite(product)) {
      // Cập nhật UI local trước bằng cách so sánh _extractProductId
      _favoriteProducts.removeWhere((item) => _extractProductId(item) == intParsedProduct);
      notifyListeners();
    } else {
      // Cập nhật UI local
      _favoriteProducts.add(product);
      notifyListeners();
    }

    // Gọi API backend
    try {
      final success = await ApiService.toggleFavoriteApi(intParsedUser, intParsedProduct);
      if (!success) {
        await loadFavorites(intParsedUser);
      }
    } catch (e) {
      debugPrint('Lỗi khi thao tác database: $e');
      await loadFavorites(intParsedUser);
    }
  }

  int? _extractProductId(Map<String, dynamic> product) {
    // Ưu tiên kiểm tra nếu product nằm lồng trong key 'Product' hoặc 'product'
    final innerProduct = product['Product'] ?? product['product'];
    final targetMap = (innerProduct is Map<String, dynamic>) ? innerProduct : product;

    final dynamic id = targetMap['ProductID'] ?? 
                      targetMap['PRODUCTID'] ?? 
                      targetMap['productId'] ?? 
                      targetMap['id'] ?? 
                      targetMap['ID'];

    if (id == null) return null;
    return id is int ? id : int.tryParse(id.toString());
  }


}