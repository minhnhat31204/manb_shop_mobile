import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login_options_screen.dart';
import 'order_history_screen.dart';
import 'favorite_products_screen.dart';
import 'address_book_screen.dart';
import 'showroom_screen.dart';
import 'user_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import './terms_policy_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    // Lắng nghe dữ liệu người dùng từ UserProvider
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final bool isLoggedIn = user != null;
    final String userName = user?['fullName'] ?? user?['FullName'] ?? 'Người dùng';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isLoggedIn, userName),
            const SizedBox(height: 12),

            // Danh sách các mục chức năng
            _buildMenuSection(context, isLoggedIn, userProvider),
          ],
        ),
      ),
    );
  }

  // Header xanh dương phía trên
  Widget _buildHeader(BuildContext context, bool isLoggedIn, String userName) {
    // Lấy thông tin avatar người dùng nếu có
    final user = Provider.of<UserProvider>(context).user;
    final String? avatarUrl = user?['Avatar'] ?? user?['avatar'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E40AF),
      ),
      child: isLoggedIn
          ? InkWell(
              onTap: () {
                // Chuyển sang màn hình Thông tin cá nhân
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                        ? NetworkImage(avatarUrl) 
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? const Icon(Icons.person, size: 36, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Text(
                              'Thông tin cá nhân',
                              style: TextStyle(color: Colors.white70, fontSize: 14,fontWeight: FontWeight.w700),
                            ),
                            Icon(Icons.chevron_right, color: Colors.white70, size: 16,),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E40AF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginOptionsScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Đăng ký / Đăng nhập',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
    );
  }


  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể thực hiện cuộc gọi đến $phoneNumber')),
        );
      }
    }
  }

  // List các menu chức năng
  Widget _buildMenuSection(
    BuildContext context,
    bool isLoggedIn,
    UserProvider userProvider,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildMenuItem(
            Icons.shopping_bag_outlined, 
            'Quản lý đơn hàng', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
          ),
          _buildMenuItem(
            Icons.favorite_border, 
            'Sản phẩm yêu thích', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteProductsScreen())),
          ),
          _buildMenuItem(
            Icons.location_on_outlined, 
            'Sổ địa chỉ', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookScreen())),
          ),
          _buildMenuItem(
            Icons.verified_user_outlined,
            'Chính sách và điều khoản',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsPolicyScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            Icons.store_outlined, 
            'Hệ thống Showroom', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShowroomScreen())),
          ),
          _buildMenuItem(
            Icons.headset_mic_outlined,
            'Chăm sóc khách hàng',
            subtitle: '1800 6865',
            onTap: () => _makePhoneCall('18006865'), // Tự động mở trình gọi điện với số 18006865
          ),
          _buildMenuItem(
            Icons.phone_in_talk_outlined,
            'Gọi mua hàng',
            subtitle: '1800 6867',
            onTap: () => _makePhoneCall('18006867'), // Tự động mở trình gọi điện với số 18006867
          ),
          if (isLoggedIn) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                // Hiển thị hộp thoại xác nhận đăng xuất
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: const Text(
                        'Xác nhận đăng xuất',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext), // Đóng dialog nếu chọn Hủy
                          child: const Text(
                            'Hủy',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(dialogContext); // Đóng dialog

                            // Gọi trực tiếp hàm logout chuẩn của UserProvider
                            Provider.of<UserProvider>(context, listen: false).logout(context: context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã đăng xuất thành công!')),
                            );
                          },
                          child: const Text(
                            'Đăng xuất',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon, 
    String title, {
    String? subtitle, 
    VoidCallback? onTap, // 1. Thêm tham số onTap ở đây
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black87),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
          onTap: onTap, // 2. Truyền tham số onTap vào ListTile
        ),
        const Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Color(0xFFF3F4F6),
        ),
      ],
    );
  }
}