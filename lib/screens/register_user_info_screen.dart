import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class RegisterUserInfoScreen extends StatefulWidget {
  final String phone;

  const RegisterUserInfoScreen({super.key, required this.phone});

  @override
  State<RegisterUserInfoScreen> createState() => _RegisterUserInfoScreenState();
}

class _RegisterUserInfoScreenState extends State<RegisterUserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _saveUserToDatabase() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> newUser = {
        'fullName': _fullNameController.text.trim(), // Sửa thành fullName
        'email': _emailController.text.trim(),       // Sửa thành email
        'password': _passwordController.text.trim(), // Sửa thành password
        'phone': widget.phone,
      };

      try {
        final response = await ApiService.registerUser(newUser);

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (!mounted) return;

          // 1. Lưu thông tin vừa đăng ký
          Provider.of<UserProvider>(context, listen: false).setUser(newUser);

          // 2. Cập nhật userId cho CartProvider (nếu response trả về UserID mới)
          final userId = newUser['UserID'] ?? newUser['id'] ?? newUser['userId'];
          Provider.of<CartProvider>(context, listen: false).setUserId(userId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký tài khoản thành công!')),
          );

          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi đăng ký: ${response.body}')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể kết nối đến máy chủ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo thông tin tài khoản')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hoàn tất thông tin cá nhân',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                keyboardType: TextInputType.name, // Cho phép tối ưu nhập họ tên & tiếng Việt
                textCapitalization: TextCapitalization.words, // Tự động viết hoa chữ cái đầu mỗi từ
                decoration: const InputDecoration(
                  labelText: 'Họ và tên (FullName)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.contains('@') ? null : 'Email không hợp lệ',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu (Password)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.phone,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại (Phone)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _saveUserToDatabase,
                  child: const Text('Hoàn tất đăng ký', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}