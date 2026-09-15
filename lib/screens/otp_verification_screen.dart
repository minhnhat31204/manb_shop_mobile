import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'register_user_info_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final String correctOtp;
  final bool isRegistered;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.correctOtp,
    required this.isRegistered,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  void _verifyOtp() async {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 chữ số OTP'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final response = await ApiService.checkUserByPhone(widget.phone);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userData = responseData['user'] ?? responseData;

        if (userData != null && userData is Map<String, dynamic>) {
          if (!mounted) return;

          Provider.of<UserProvider>(context, listen: false)
              .setUser(userData, context: context);

          final userId =
              userData['UserID'] ?? userData['id'] ?? userData['userId'];

          if (userId != null) {
            final parsedUserId =
                userId is int ? userId : int.tryParse(userId.toString());

            if (parsedUserId != null) {
              Provider.of<CartProvider>(context, listen: false)
                  .setUserId(parsedUserId);
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng nhập thành công!'),
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.popUntil(context, (route) => route.isFirst);
          return;
        }
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterUserInfoScreen(phone: widget.phone),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1D4ED8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icon Khóa Xác Thựcs
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 56,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              // Tiêu đề & Chú thích
              const Text(
                'Xác thực OTP',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.4),
                  children: [
                    const TextSpan(text: 'Mã xác thực gồm 6 chữ số đã được gửi đến\n'),
                    TextSpan(
                      text: widget.phone,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Ô nhập mã OTP dạng nổi bật
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 16,
                  color: Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                    color: Colors.grey.shade300,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Nút Xác thực full-width
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _verifyOtp,
                  child: const Text(
                    'Xác thực',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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