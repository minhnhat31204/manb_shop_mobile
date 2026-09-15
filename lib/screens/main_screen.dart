import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import 'home_screen.dart';
import 'category_sheet.dart';
import 'product_list_screen.dart';
import 'cart_screen.dart';
import 'account_screen.dart';
import 'notification_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isCategoryOpen = false;
  String? _selectedCategoryTitle;

  void _onItemTapped(int index) {
    if (index == 1) {
      setState(() {
        _isCategoryOpen = !_isCategoryOpen;
      });
    } else {
      setState(() {
        _selectedIndex = index;
        _isCategoryOpen = false;
        _selectedCategoryTitle = null;
      });
    }
  }

  void _closeCategory() {
    setState(() {
      _isCategoryOpen = false;
    });
  }

  Widget _getCategoryTabWidget() {
    if (_selectedCategoryTitle != null) {
      return ProductListScreen(
        categoryTitle: _selectedCategoryTitle!,
        onGoToHome: () {
          setState(() {
            _selectedIndex = 0;
            _selectedCategoryTitle = null;
          });
        },
      );
    }
    return const Center(
      child: Text(
        'Vui lòng chọn một danh mục',
        style: TextStyle(color: Colors.grey, fontSize: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double bottomNavHeight = 65.0;

    final List<Widget> pages = [
      const HomeScreen(),
      _getCategoryTabWidget(),
      CartScreen(
        onSelectTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ), // 👈 Đã thêm callback nhận việc đổi Tab
      const NotificationScreen(),
      const AccountScreen(),
    ];

    // Lắng nghe tổng số lượng items trong giỏ hàng từ CartProvider
    final cartItemCount = context.watch<CartProvider>().totalItemsCount;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: bottomNavHeight),
              child: IndexedStack(index: _selectedIndex, children: pages),
            ),
          ),
          if (_isCategoryOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeCategory,
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _isCategoryOpen
                ? bottomNavHeight
                : -MediaQuery.of(context).size.height,
            height:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                50 -
                bottomNavHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.antiAlias,
              child: CategoryBottomSheetContent(
                onClose: _closeCategory,
                onSelectSubCategory: (selectedSubCategory) {
                  setState(() {
                    _selectedCategoryTitle = selectedSubCategory;
                    _selectedIndex = 1;
                    _isCategoryOpen = false;
                  });
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomNavHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
                ),
              ),
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: BottomNavigationBar(
                  currentIndex: _isCategoryOpen ? 1 : _selectedIndex,
                  onTap: _onItemTapped,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  iconSize: 22.0,
                  selectedItemColor: const Color(0xFF1D4ED8),
                  unselectedItemColor: const Color(0xFF71717A),
                  selectedFontSize: 10.5,
                  unselectedFontSize: 10.5,
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home_rounded),
                      label: 'Trang chủ',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.grid_view_outlined),
                      activeIcon: Icon(Icons.grid_view_rounded),
                      label: 'Danh mục',
                    ),
                    BottomNavigationBarItem(
                      icon: Badge(
                        label: Text('$cartItemCount'),
                        backgroundColor: const Color(0xFFDC2626),
                        isLabelVisible: cartItemCount > 0,
                        child: const Icon(Icons.shopping_cart_outlined),
                      ),
                      activeIcon: Badge(
                        label: Text('$cartItemCount'),
                        backgroundColor: const Color(0xFFDC2626),
                        isLabelVisible: cartItemCount > 0,
                        child: const Icon(Icons.shopping_cart),
                      ),
                      label: 'Giỏ hàng',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.notifications_none_outlined),
                      activeIcon: Icon(Icons.notifications),
                      label: 'Thông báo',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.account_circle_outlined),
                      activeIcon: Icon(Icons.account_circle),
                      label: 'Tài khoản',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
