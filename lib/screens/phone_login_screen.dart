import 'dart:math';
import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';
import '../services/api_service.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  Future<bool> _checkPhoneInDatabase(String phone) async {
    final user = await ApiService.getUserByPhone(phone);
    return user != null;
  }

  void _handleContinue() async {
    String phone = _phoneController.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số điện thoại hợp lệ'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String generatedOtp = (100000 + Random().nextInt(900000)).toString();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mã OTP thử nghiệm của bạn là: $generatedOtp'),
        duration: const Duration(seconds: 8),
        backgroundColor: const Color(0xFF1E40AF),
        behavior: SnackBarBehavior.floating,
      ),
    );

    bool isRegistered = await _checkPhoneInDatabase(phone);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phone: phone,
          correctOtp: generatedOtp,
          isRegistered: isRegistered,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E40AF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937), size: 20),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'lib/images/logo.png',
                  height: 64,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.storefront_rounded,
                    size: 56,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nhập số điện thoại',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sử dụng số điện thoại để đăng nhập hoặc tạo tài khoản mới',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  hintText: '0912 345 678',
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF6B7280)),
                  labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                  floatingLabelStyle: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                  onPressed: _handleContinue,
                  child: const Text(
                    'Tiếp tục',
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