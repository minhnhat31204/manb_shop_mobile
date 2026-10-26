import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'register_user_info_screen.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'order_history_screen.dart';
import 'favorite_products_screen.dart';
import 'address_book_screen.dart';
import 'showroom_screen.dart';
import 'user_profile_screen.dart';
import 'terms_policy_screen.dart';
import 'chat_screen.dart';
import '../providers/chat_provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final bool isLoggedIn = user != null;
    final String userName =
        user?['fullName'] ?? user?['FullName'] ?? 'Người dùng';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, isLoggedIn, userName),
            const SizedBox(height: 12),
            _buildMenuSection(context, isLoggedIn, userProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLoggedIn, String userName) {
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
      decoration: const BoxDecoration(color: Color(0xFF1E40AF)),
      child: isLoggedIn
          ? InkWell(
              onTap: () {
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
                        ? const Icon(
                            Icons.person,
                            size: 36,
                            color: Colors.white,
                          )
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
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white70,
                              size: 16,
                            ),
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
                    horizontal: 100,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: () {
                  _showLoginModalSheet(context);
                },
                child: const Text(
                  'Đăng ký / Đăng nhập',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
    );
  }

  void _showLoginModalSheet(BuildContext context) {
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    String? phoneError;
    String? passwordError;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            Future<void> handleLogin() async {
              setStateModal(() {
                phoneError = null;
                passwordError = null;
              });

              final phone = phoneController.text.trim();
              final password = passwordController.text.trim();

              if (phone.isEmpty) {
                setStateModal(() => phoneError = 'Vui lòng nhập số điện thoại');
                return;
              }
              if (password.isEmpty) {
                setStateModal(() => passwordError = 'Vui lòng nhập mật khẩu');
                return;
              }

              setStateModal(() => isLoading = true);

              try {
                final response = await ApiService.login({'phone': phone, 'password': password});
                final data = jsonDecode(response.body);

                if (response.statusCode == 200) {
                  if (context.mounted) {
                    Provider.of<UserProvider>(context, listen: false).setUser(data['user'], context: context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đăng nhập thành công!')),
                    );
                  }
                } else {
                  setStateModal(() {
                    final msg = data['error'] ?? 'Đăng nhập thất bại';
                    if (msg.contains('mật khẩu') || msg.contains('không đúng')) {
                      passwordError = msg;
                      phoneError = msg;
                    } else {
                      phoneError = msg;
                    }
                  });
                }
              } catch (e) {
                setStateModal(() => phoneError = 'Lỗi kết nối máy chủ');
              } finally {
                setStateModal(() => isLoading = false);
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Đăng nhập', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),

                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: const Icon(Icons.phone_android),
                          errorText: phoneError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          errorText: passwordError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showForgotPasswordDialog(context);
                          },
                          child: const Text('Quên mật khẩu?', style: TextStyle(color: Colors.blue)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E40AF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Đăng nhập', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Nếu bạn chưa có tài khoản, hãy ',
                            style: TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterUserInfoScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'đăng ký',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1E40AF),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();

    int step = 1;
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            Future<void> handleSendOtp() async {
              if (emailController.text.trim().isEmpty || !emailController.text.contains('@')) {
                setStateModal(() => errorMessage = 'Vui lòng nhập email hợp lệ');
                return;
              }
              setStateModal(() { isLoading = true; errorMessage = null; });
              try {
                final res = await ApiService.sendPasswordResetOtp(emailController.text.trim());
                final data = jsonDecode(res.body);
                if (res.statusCode == 200) {
                  setStateModal(() => step = 2);
                } else {
                  setStateModal(() => errorMessage = data['error'] ?? 'Không gửi được OTP');
                }
              } catch (e) {
                setStateModal(() => errorMessage = 'Lỗi kết nối máy chủ');
              } finally {
                setStateModal(() => isLoading = false);
              }
            }

            Future<void> handleVerifyOtp() async {
              if (otpController.text.trim().isEmpty) {
                setStateModal(() => errorMessage = 'Vui lòng nhập mã OTP');
                return;
              }
              setStateModal(() { isLoading = true; errorMessage = null; });
              try {
                final res = await ApiService.verifyPasswordResetOtp(
                  emailController.text.trim(),
                  otpController.text.trim(),
                );
                final data = jsonDecode(res.body);
                if (res.statusCode == 200) {
                  setStateModal(() => step = 3);
                } else {
                  setStateModal(() => errorMessage = data['error'] ?? 'Mã OTP không hợp lệ');
                }
              } catch (e) {
                setStateModal(() => errorMessage = 'Lỗi kết nối máy chủ');
              } finally {
                setStateModal(() => isLoading = false);
              }
            }

            Future<void> handleResetPassword() async {
              if (newPasswordController.text.trim().length < 8) {
                setStateModal(() => errorMessage = 'Mật khẩu phải có ít nhất 8 ký tự.');
                return;
              }
              setStateModal(() { isLoading = true; errorMessage = null; });
              try {
                final res = await ApiService.resetPassword(
                  emailController.text.trim(),
                  newPasswordController.text.trim(),
                );
                final data = jsonDecode(res.body);
                if (res.statusCode == 200) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đặt lại mật khẩu thành công! Hãy đăng nhập lại.')),
                    );
                  }
                } else {
                  setStateModal(() => errorMessage = data['error'] ?? 'Đổi mật khẩu thất bại');
                }
              } catch (e) {
                setStateModal(() => errorMessage = 'Lỗi kết nối máy chủ');
              } finally {
                setStateModal(() => isLoading = false);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                step == 1 ? 'Quên mật khẩu' : (step == 2 ? 'Nhập mã OTP' : 'Mật khẩu mới'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ),

                    if (step == 1) ...[
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email đăng ký',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else if (step == 2) ...[
                      Text('Mã OTP đã gửi đến email:\n${emailController.text}', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nhập mã OTP',
                          prefixIcon: Icon(Icons.security),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mật khẩu mới (tối thiểu 8 ký tự)',
                          prefixIcon: Icon(Icons.lock_reset),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : (step == 1 ? handleSendOtp : (step == 2 ? handleVerifyOtp : handleResetPassword)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E40AF)),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(step == 1 ? 'Gửi OTP' : (step == 2 ? 'Xác nhận' : 'Đổi mật khẩu'), style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể thực hiện cuộc gọi đến $phoneNumber'),
          ),
        );
      }
    }
  }

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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            ),
          ),
          _buildMenuItem(
            Icons.favorite_border,
            'Sản phẩm yêu thích',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoriteProductsScreen()),
            ),
          ),
          _buildMenuItem(
            Icons.location_on_outlined,
            'Sổ địa chỉ',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddressBookScreen()),
            ),
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShowroomScreen()),
            ),
          ),
          _buildMenuItem(
            Icons.headset_mic_outlined,
            'Chăm sóc khách hàng',
            subtitle: '1800 6865',
            onTap: () => _makePhoneCall('18006865'),
          ),
          _buildMenuItem(
            Icons.phone_in_talk_outlined,
            'Gọi mua hàng',
            subtitle: '1800 6867',
            onTap: () => _makePhoneCall('18006867'),
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
                      content: const Text(
                        'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
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
                            Navigator.pop(dialogContext);
                            Provider.of<UserProvider>(
                              context,
                              listen: false,
                            ).logout(context: context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã đăng xuất thành công!'),
                              ),
                            );
                          },
                          child: const Text(
                            'Đăng xuất',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
    VoidCallback? onTap,
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
          onTap: onTap,
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