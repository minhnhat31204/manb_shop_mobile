import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class VNPAYQRScreen extends StatefulWidget {
  final double totalAmount;
  final String? orderId;
  final String? bankName;
  final List<dynamic>? checkoutItems;
  // THÊM CÁC THÔNG TIN KHÁCH HÀNG
  final String? recipientName;
  final String? recipientPhone;
  final String? shippingAddress;
  final String? note;

  const VNPAYQRScreen({
    super.key,
    required this.totalAmount,
    this.orderId,
    this.bankName,
    this.checkoutItems,
    this.recipientName,
    this.recipientPhone,
    this.shippingAddress,
    this.note,
  });

  @override
  State<VNPAYQRScreen> createState() => _VNPAYQRScreenState();
}

class _VNPAYQRScreenState extends State<VNPAYQRScreen> {
  Timer? _timer;
  int _startSeconds = 15 * 60; // 15 phút
  late String orderCode;

  // BẢNG MÀU CHỦ ĐẠO: XANH & TRẮNG
  static const Color primaryColor = Color(0xFF1E40AF);
  static const Color primaryAccent = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    orderCode = widget.orderId ?? _generateRandomOrderCode();
    _startTimer();
  }

  String _generateRandomOrderCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final String randomString = List.generate(
      10,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    return 'TL$randomString';
  }

  String _formatCurrency(double amount) {
    int value = amount.round();
    String result = value.toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    result = result.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$result đ';
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startSeconds == 0) {
        setState(() => timer.cancel());
        _showTimeoutDialog();
      } else {
        setState(() => _startSeconds--);
      }
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Hết thời gian thanh toán'),
        content: const Text('Giao dịch của bạn đã hết hạn thanh toán. Vui lòng thực hiện lại.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Đồng ý', style: TextStyle(color: primaryColor)),
          )
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text('Bạn có chắc chắn muốn hủy yêu cầu thanh toán này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // Xác nhận sau khi chuyển khoản
  Future<void> _confirmPayment() async {
    _timer?.cancel();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: primaryColor),
      ),
    );

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUserId;

      final itemsList = (widget.checkoutItems ?? []).map((item) {
        return {
          'ProductID': item['ProductID'] ?? item['PRODUCTID'] ?? item['ID'] ?? 0,
          'Quantity': item['Quantity'] ?? item['QUANTITY'] ?? 1,
          'Price': (item['DiscountPrice'] ?? item['DISCOUNTPRICE'] ?? item['Price'] ?? 0.0).toDouble(),
        };
      }).toList();

      final response = await ApiService.createOrder({
        'UserID': userId,
        'OrderId': orderCode,
        'TotalAmount': widget.totalAmount,
        'PaymentMethod': widget.bankName ?? 'VNPAY-QR',
        'Status': 'Pending',
        'RecipientName': widget.recipientName,
        'RecipientPhone': widget.recipientPhone,
        'ShippingAddress': widget.shippingAddress,
        'Note': widget.note ?? '',
        'Items': itemsList,
      });

      if (!mounted) return;
      Navigator.pop(context); // Đóng Loading

      if (response.statusCode == 200 || response.statusCode == 201) {
        await Provider.of<CartProvider>(context, listen: false).clearCart();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Đã gửi xác nhận thanh toán'),
            content: const Text('Hệ thống đang kiểm tra giao dịch và sẽ cập nhật trạng thái đơn hàng trong giây lát.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Hoàn tất', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
        Provider.of<NotificationProvider>(context, listen: false).addNotification(
          title: 'Thanh toán thành công',
          message: 'Đơn hàng #$orderCode của bạn đã thanh toán thành công và đang chờ xử lý.',
          type: 'order_success',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu đơn hàng thất bại! Mã lỗi: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể kết nối máy chủ: $e')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getBankQrImage(String? bankName) {
    if (bankName == null) return 'lib/images/qr_default.png';
    if (bankName.contains('Vietcombank')) return 'lib/images/vietcombank.png';
    if (bankName.contains('BIDV')) return 'lib/images/bidv.png';
    if (bankName.contains('Techcombank')) return 'lib/images/techcombank.png';
    return 'lib/images/qr_default.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Cổng thanh toán VNPAYQR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: _showCancelDialog,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Thẻ chứa thông tin thời gian & số tiền
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Đếm ngược thời gian
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      const Text(
                        'Hết hạn sau:',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatTime(_startSeconds),
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),
                  
                  // Mã đơn hàng & Tổng tiền
                  Text(
                    'Mã đơn hàng: $orderCode',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatCurrency(widget.totalAmount),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 0, 0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mã QR Code trong Card trắng
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      _getBankQrImage(widget.bankName),
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.qr_code_2_rounded, size: 200, color: primaryColor);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.crop_free_rounded, size: 16, color: primaryAccent),
                      SizedBox(width: 6),
                      Text(
                        'Quét mã QR bằng ứng dụng ngân hàng',
                        style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Nút bấm xác nhận & Hủy thanh toán
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 2,
                  shadowColor: primaryColor.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _confirmPayment,
                child: const Text(
                  'Tôi đã chuyển khoản xong',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _showCancelDialog,
              child: const Text(
                'Hủy thanh toán',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}