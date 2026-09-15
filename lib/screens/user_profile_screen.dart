import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../providers/notification_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _birthdayController;

  String _gender = 'Nam';
  String _avatarUrl = '';
  File? _selectedImageFile;

  // Màu sắc chủ đạo Xanh - Trắng
  static const Color primaryBlue = Color(0xFF1D4ED8);
  static const Color lightBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user ?? {};

    _nameController = TextEditingController(text: user['FullName'] ?? user['fullName'] ?? '');
    _emailController = TextEditingController(text: user['Email'] ?? user['email'] ?? '');
    _phoneController = TextEditingController(text: user['Phone'] ?? user['phone'] ?? '');
    _addressController = TextEditingController(text: user['Address'] ?? user['address'] ?? '');
    _avatarUrl = user['Avatar'] ?? user['avatar'] ?? '';

    String rawBirthday = user['Birthday'] ?? user['birthday'] ?? '';
    if (rawBirthday.length >= 10) {
      rawBirthday = rawBirthday.substring(0, 10);
    }
    _birthdayController = TextEditingController(text: rawBirthday);

    final rawGender = user['Gender'] ?? user['gender'];
    if (rawGender != null && rawGender.toString().isNotEmpty) {
      _gender = rawGender.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropAvatar() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryBlue),
              title: const Text('Chọn ảnh từ Thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _processImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: primaryBlue),
              title: const Text('Nhập đường dẫn ảnh (URL)'),
              onTap: () {
                Navigator.pop(ctx);
                _showUrlInputDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Căn chỉnh Avatar',
            toolbarColor: primaryBlue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Căn chỉnh Avatar',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImageFile = File(croppedFile.path);
          _avatarUrl = croppedFile.path;
        });
      }
    }
  }

  void _showUrlInputDialog() {
    final urlController = TextEditingController(text: _avatarUrl.startsWith('http') ? _avatarUrl : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập đường dẫn Avatar (URL)'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com/avatar.png',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            onPressed: () {
              setState(() {
                _avatarUrl = urlController.text.trim();
                _selectedImageFile = null;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    if (!_isEditing) return;
    DateTime initialDate = DateTime.tryParse(_birthdayController.text) ?? DateTime(2000, 1, 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?['UserID'] ?? userProvider.user?['userID'];

    final updateData = {
      'FullName': _nameController.text.trim(),
      'Email': _emailController.text.trim(),
      'Avatar': _avatarUrl,
      'Address': _addressController.text.trim(),
      'Gender': _gender,
      'Birthday': _birthdayController.text.trim().isEmpty ? null : _birthdayController.text.trim(),
    };

    try {
      final res = await ApiService.put('/users/$userId', updateData);

      if (res.statusCode == 200 || res.statusCode == 204) {
        final updatedUser = Map<String, dynamic>.from(userProvider.user!);
        updatedUser.addAll(updateData);
        userProvider.setUser(updatedUser);

        setState(() {
          _isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin thành công!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
        Provider.of<NotificationProvider>(context, listen: false).addNotification(
          title: 'Cập nhật tài khoản thành công',
          message: 'Bạn vừa cập nhật thông tin cá nhân.',
          type: 'account',
        );
      } else {
        throw Exception('Cập nhật thất bại');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String labelText, {Widget? suffixIcon, bool isDisabled = false}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: isDisabled ? Colors.grey : const Color(0xFF475569)),
      filled: isDisabled || !_isEditing,
      fillColor: isDisabled ? const Color(0xFFF1F5F9) : (_isEditing ? Colors.white : const Color(0xFFF8FAFC)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      suffixIcon: suffixIcon,
      errorMaxLines: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImageProvider;
    if (_selectedImageFile != null) {
      avatarImageProvider = FileImage(_selectedImageFile!);
    } else if (_avatarUrl.isNotEmpty && _avatarUrl.startsWith('http')) {
      avatarImageProvider = NetworkImage(_avatarUrl);
    }

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryBlue.withValues(alpha: 0.3), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage: avatarImageProvider,
                        child: avatarImageProvider == null
                            ? const Icon(Icons.person, size: 50, color: Color(0xFF94A3B8))
                            : null,
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _pickAndCropAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Họ và tên
              TextFormField(
                controller: _nameController,
                enabled: _isEditing,
                decoration: _buildInputDecoration('Họ và tên'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng không để trống Họ và tên' : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                enabled: _isEditing,
                decoration: _buildInputDecoration('Email'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng không để trống Email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                    return 'Định dạng Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Số điện thoại (Khóa)
              TextFormField(
                controller: _phoneController,
                enabled: false,
                decoration: _buildInputDecoration(
                  'Số điện thoại',
                  suffixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF94A3B8)),
                  isDisabled: true,
                ),
              ),
              const SizedBox(height: 16),

              // Địa chỉ
              TextFormField(
                controller: _addressController,
                enabled: _isEditing,
                decoration: _buildInputDecoration('Địa chỉ'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng không để trống Địa chỉ' : null,
              ),
              const SizedBox(height: 16),

              // Ngày sinh
              TextFormField(
                controller: _birthdayController,
                readOnly: true,
                onTap: _selectDate,
                enabled: _isEditing,
                decoration: _buildInputDecoration(
                  'Ngày sinh (YYYY-MM-DD)',
                  suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20, color: primaryBlue),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng không để trống Ngày sinh' : null,
              ),
              const SizedBox(height: 16),

              // Giới tính
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: _buildInputDecoration('Giới tính'),
                items: const [
                  DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                  DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                  DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                ],
                onChanged: _isEditing
                    ? (val) {
                        if (val != null) setState(() => _gender = val);
                      }
                    : null,
              ),
              const SizedBox(height: 28),

              // Nút bấm
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isEditing
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isLoading ? null : _saveProfile,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Lưu thay đổi',
                                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                        label: const Text(
                          'Chỉnh sửa thông tin',
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}