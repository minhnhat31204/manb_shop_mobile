import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  Map<String, dynamic>? _selectedVoucher;
  bool _isLoading = false;
  
  int? _userId;
  final String baseUrl = 'http://192.168.154.1:5000/api';

  List<Map<String, dynamic>> get cartItems => _cartItems;
  Map<String, dynamic>? get selectedVoucher => _selectedVoucher;
  bool get isLoading => _isLoading;
  int? get userId => _userId;

  // Hàm chọn hoặc bỏ chọn Voucher (Checkbox)
  void toggleVoucher(Map<String, dynamic> voucher) {
    if (_selectedVoucher != null && _selectedVoucher!['VoucherID'] == voucher['VoucherID']) {
      _selectedVoucher = null; // Nếu bấm lại voucher đang chọn -> Bỏ chọn
    } else {
      _selectedVoucher = voucher; // Chọn voucher mới
    }
    notifyListeners();
  }

  // Cập nhật User ID và tải lại giỏ hàng tương ứng
  void setUserId(int? id) {
    _userId = id;
    if (_userId != null) {
      fetchCartFromDB();
    } else {
      _cartItems = []; // Đăng xuất thì làm sạch giỏ hàng trên giao diện
      notifyListeners();
    }
  }

  int get totalItemsCount {
    int total = 0;
    for (var item in _cartItems) {
      total += (item['Quantity'] ?? item['quantity'] ?? 1) as int;
    }
    return total;
  }

  double get subtotal {
    double sum = 0.0;
    for (var item in _cartItems) {
      final double price = (item['DiscountPrice'] ?? item['DISCOUNTPRICE'] ?? item['discountPrice'] ?? item['Price'] ?? item['PRICE'] ?? 0.0).toDouble();
      final int qty = (item['Quantity'] ?? item['QUANTITY'] ?? 1) as int;
      sum += price * qty;
    }
    return sum;
  }

  double get discountAmount {
    if (_selectedVoucher == null) return 0.0;
    final double discountPercent = (_selectedVoucher!['DiscountPercentage'] ?? 0.0).toDouble();
    final double maxDiscount = (_selectedVoucher!['MaxDiscountAmount'] ?? double.infinity).toDouble();
    double calculatedDiscount = subtotal * (discountPercent / 100);
    return calculatedDiscount > maxDiscount ? maxDiscount : calculatedDiscount;
  }

  double get totalAmount {
    double finalTotal = subtotal - discountAmount;
    return finalTotal < 0 ? 0 : finalTotal;
  }

  // LẤY DỮ LIỆU GIỎ HÀNG THEO USER ID TỪ SQL SERVER
  Future<void> fetchCartFromDB() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('$baseUrl/cart/$_userId'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _cartItems = List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      print("Lỗi kết nối CSDL SQL Server: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(Map<String, dynamic> product, [int quantity = 1]) async {
    if (_userId == null) return false;

    final int productId = product['ProductID'] ?? product['productID'] ?? product['ID'] ?? 0;
    final double originalPrice = (product['Price'] ?? product['PRICE'] ?? 0.0).toDouble();
    final double discountPrice = (product['DiscountPrice'] ?? product['DISCOUNTPRICE'] ?? originalPrice).toDouble();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'UserID': _userId,
          'ProductID': productId,
          'Quantity': quantity,
          'Price': originalPrice,
          'DiscountPrice': discountPrice,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCartFromDB();
        return true;
      }
    } catch (e) {
      print("Lỗi thêm giỏ hàng: $e");
    }
    return false;
  }

  Future<void> updateQuantity(int cartItemId, int newQuantity) async {
    if (newQuantity <= 0) return;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cart/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ID': cartItemId, 'Quantity': newQuantity}),
      );

      if (response.statusCode == 200) {
        final index = _cartItems.indexWhere((element) => (element['ID'] ?? element['id']) == cartItemId);
        if (index != -1) {
          _cartItems[index]['Quantity'] = newQuantity;
          notifyListeners();
        }
      }
    } catch (e) {
      print("Lỗi cập nhật số lượng: $e");
    }
  }

  Future<bool> removeFromCart(int cartItemId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/cart/$cartItemId'));
      if (response.statusCode == 200) {
        _cartItems.removeWhere((item) => (item['ID'] ?? item['id']) == cartItemId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Lỗi xóa sản phẩm: $e");
    }
    return false;
  }

  Future<void> clearCart() async {
    try {
      if (_userId != null) {
        // Gọi API xóa toàn bộ giỏ hàng của user trên server (nếu backend có hỗ trợ)
        await http.delete(Uri.parse('$baseUrl/cart/clear/$_userId'));
      }
    } catch (e) {
      print("Lỗi xóa toàn bộ giỏ hàng: $e");
    } finally {
      // Làm sạch danh sách sản phẩm và voucher ở client
      _cartItems = [];
      _selectedVoucher = null;
      notifyListeners();
    }
  }

  void applyVoucher(Map<String, dynamic> voucher) {
    _selectedVoucher = voucher;
    notifyListeners();
  }

  void removeVoucher() {
    _selectedVoucher = null;
    notifyListeners();
  }
}