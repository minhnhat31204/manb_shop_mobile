import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/chat_provider.dart';
import 'home_screen.dart';
import 'category_sheet.dart';
import 'product_list_screen.dart';
import 'cart_screen.dart';
import 'account_screen.dart';
import 'notification_screen.dart';
import 'chat_screen.dart';

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

  void _showChatOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Trung tâm Hỗ trợ & Tư vấn Trực tuyến',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chọn kênh hỗ trợ để được giải đáp thắc mắc và kiểm tra máy nhanh nhất:',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                tileColor: const Color(0xFFFAF5FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE9D5FF)),
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🤖', style: TextStyle(fontSize: 22)),
                  ),
                ),
                title: Row(
                  children: [
                    const Text('Trợ lý AI 24/7', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                subtitle: const Text('Tư vấn cấu hình máy & tra cứu tồn kho tức thì', style: TextStyle(fontSize: 11.5)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatScreen(initialChannel: ChatChannel.ai),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                tileColor: const Color(0xFFEFF6FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('👨‍💼', style: TextStyle(fontSize: 22)),
                  ),
                ),
                title: const Text('Nhắn tin CSKH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Kết nối nhân viên trực tuyến đồng bộ với Web', style: TextStyle(fontSize: 11.5)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatScreen(initialChannel: ChatChannel.staff),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
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
      ),
      const NotificationScreen(),
      const AccountScreen(),
    ];

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

          // Floating Support Chat Button (Tương tự SupportWidget trên Web)
          if (!_isCategoryOpen)
            Positioned(
              right: 16,
              bottom: bottomNavHeight + 16,
              child: FloatingActionButton.extended(
                heroTag: 'support_chat_fab',
                onPressed: _showChatOptionsModal,
                backgroundColor: const Color(0xFF1E40AF),
                elevation: 6,
                icon: const Text('💬', style: TextStyle(fontSize: 18)),
                label: const Text(
                  'Hỗ trợ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
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
                  selectedItemColor: const Color(0xFF1E40AF),
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

