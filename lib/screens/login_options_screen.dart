import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'phone_login_screen.dart';

import 'dart:convert';

class LoginOptionsScreen extends StatelessWidget {
  const LoginOptionsScreen({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (context.mounted && userCredential.user != null) {
        final user = userCredential.user!;

        // 1. Gọi Backend lưu/lấy user từ Cơ sở dữ liệu
        final response = await ApiService.googleLogin(
          fullName: user.displayName ?? 'Người dùng',
          email: user.email ?? '',
          avatar: user.photoURL ?? '',
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final dbUserData = responseData['user'];

          if (context.mounted) {
            // 2. Lưu thông tin đầy đủ từ CSDL vào Provider
            Provider.of<UserProvider>(
              context,
              listen: false,
            ).setUser(dbUserData, context: context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Xin chào ${user.displayName}')),
            );

            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đăng nhập thất bại: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1D4ED8); // Màu xanh dương thương hiệu

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1F2937),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo Thương Hiệu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'lib/images/logo.png',
                  height: 72,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.storefront_rounded,
                    size: 64,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tiêu đề & Chú thích
              const Text(
                'Chào mừng bạn!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng chọn phương thức đăng nhập để tiếp tục',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),

              const Spacer(flex: 3),

              // Nút Đăng nhập Google
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _handleGoogleSignIn(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Google chuẩn PNG (Link CDN ổn định)
                      Image.network(
                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQMhtCHWrNb2M7tAlOyQV4EFSTLSNBoyv7XR5pvLhEScg&s=10',
                        height: 22,
                        width: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tiếp tục với Google',
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Đường phân cách (Divider)
              Row(
                children: [
                  Expanded(
                    child: Container(height: 1, color: const Color(0xFFE5E7EB)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'hoặc',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Container(height: 1, color: const Color(0xFFE5E7EB)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nút Đăng nhập Số điện thoại
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PhoneLoginScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_android_rounded, size: 20),
                  label: const Text(
                    'Tiếp tục với số điện thoại',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Điều khoản sử dụng ở footer
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Bằng việc tiếp tục, bạn đồng ý với Điều khoản dịch vụ & Chính sách của chúng tôi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
