import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'favorite_provider.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _user != null;

  // Thêm getter giúp lấy userId chuẩn int ở mọi màn hình
  int? get currentUserId {
    if (_user == null) return null;
    final rawId = _user!['UserID'] ?? 
                  _user!['UserId'] ?? 
                  _user!['USERID'] ?? 
                  _user!['id'] ?? 
                  _user!['ID'] ?? 
                  _user!['userId'];
    if (rawId == null) return null;
    return rawId is int ? rawId : int.tryParse(rawId.toString());
  }

  // Thêm tham số context (không bắt buộc) để gọi các Provider khác
  void setUser(Map<String, dynamic>? userData, {BuildContext? context}) {
    _user = userData;
    notifyListeners();

    if (context != null && userData != null) {
      final userId = currentUserId;
      if (userId != null) {
        Provider.of<CartProvider>(context, listen: false).setUserId(userId);
        Provider.of<FavoriteProvider>(context, listen: false).loadFavorites(userId);
      }
    }
  }

  // Tự động reset dữ liệu khi đăng xuất
  void logout({BuildContext? context}) {
    _user = null;
    notifyListeners();

    if (context != null) {
      Provider.of<CartProvider>(context, listen: false).setUserId(null);
      Provider.of<FavoriteProvider>(context, listen: false).clearFavorites();
    }
  }
}