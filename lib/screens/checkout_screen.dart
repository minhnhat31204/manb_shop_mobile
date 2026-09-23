import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import 'payment_method_screen.dart';
import 'vnpay_qr_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic>? directBuyItem;

  const CheckoutScreen({super.key, this.directBuyItem});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? selectedPayment;
  bool showPaymentError = false;

  bool installFree = false;
  bool techSupport = false;
  bool vatInvoice = false;

  final double shippingFee = 40000.0;

  // BẢNG MÀU CHỦ ĐẠO: XANH & TRẮNG (BLUE & WHITE THEME)
  static const Color primaryColor = Color(0xFF1E40AF); // Xanh dương đậm chủ đạo
  static const Color primaryAccent = Color(0xFF2563EB); // Xanh dương tươi làm điểm nhấn
  static const Color primaryLight = Color(0xFFEFF6FF); // Xanh nhạt làm nền icon/box
  static const Color backgroundColor = Color(0xFFF8FAFC); // Nền sáng xám xanh dịu mắt
  static const Color cardColor = Colors.white; // Nền thẻ trắng tinh

  String formatCurrency(dynamic price) {
    if (price == null) return '0 đ';
    int value = (price is double) ? price.round() : (price as int);
    String result = value.toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    result = result.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$result đ';
  }

  Future<void> _openGoogleMaps(String address) async {
    if (address.isEmpty) return;
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  // Tiêu đề mỗi section với Icon xanh
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Khung Card trắng viền bo mượt với đổ bóng nhẹ
  BoxDecoration _cardDecoration({Border? border}) {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(8),
      border: border ?? Border.all(color: const Color(0xFFE2E8F0), width: 1),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user ?? {};

    final String fullName = user['FullName'] ?? user['fullName'] ?? 'Chưa cập nhật tên';
    final String phone = user['Phone'] ?? user['phone'] ?? 'Chưa cập nhật SĐT';
    final String address = user['Address'] ?? user['address'] ?? 'Chưa cập nhật địa chỉ';

    final List<Map<String, dynamic>> checkoutItems =
        widget.directBuyItem != null
            ? [widget.directBuyItem!]
            : cartProvider.cartItems.cast<Map<String, dynamic>>();

    double subtotal = 0.0;
    if (widget.directBuyItem != null) {
      final double price = (widget.directBuyItem!['DiscountPrice'] ??
              widget.directBuyItem!['DISCOUNTPRICE'] ??
              widget.directBuyItem!['Price'] ??
              0.0)
          .toDouble();
      final int qty = (widget.directBuyItem!['Quantity'] ?? widget.directBuyItem!['QUANTITY'] ?? 1) as int;
      subtotal = price * qty;
    } else {
      subtotal = cartProvider.totalAmount;
    }

    final double techSupportFee = techSupport ? 55000.0 : 0.0;
    final double discount = widget.directBuyItem != null ? 0.0 : cartProvider.discountAmount;
    final double grandTotal = subtotal + shippingFee + techSupportFee - discount;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Xác nhận đơn hàng',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: primaryColor, // Thanh AppBar màu xanh chủ đạo
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. THÔNG TIN NHẬN HÀNG
            _buildSectionHeader('Thông tin nhận hàng', Icons.location_on_rounded),
            Container(
              decoration: _cardDecoration(),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () => _openGoogleMaps(address),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.map_rounded, color: primaryColor, size: 22),
                  ),
                  // Code mới đã được sửa lỗi:
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($phone)',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      address,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. PHƯƠNG THỨC THANH TOÁN
            _buildSectionHeader('Phương thức thanh toán', Icons.payment_rounded),
            Container(
              decoration: _cardDecoration(
                border: showPaymentError
                    ? Border.all(color: Colors.red.shade400, width: 1.5)
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selectedPayment == null ? primaryLight : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: selectedPayment == null ? primaryAccent : primaryColor,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    selectedPayment ?? 'Chọn phương thức thanh toán',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selectedPayment == null ? FontWeight.normal : FontWeight.w600,
                      color: selectedPayment == null ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 16),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaymentMethodScreen(),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        selectedPayment = result;
                        showPaymentError = false;
                      });
                    }
                  },
                ),
              ),
            ),
            if (showPaymentError) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Vui lòng chọn phương thức thanh toán trước khi tiếp tục!',
                      style: TextStyle(color: Colors.red.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // 3. DANH SÁCH SẢN PHẨM
            _buildSectionHeader('Danh sách sản phẩm (${checkoutItems.length})', Icons.shopping_bag_rounded),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: checkoutItems.length,
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Colors.grey.shade200),
                ),
                itemBuilder: (context, index) {
                  final item = checkoutItems[index];
                  final String title = item['ProductName'] ?? item['PRODUCTNAME'] ?? 'Sản phẩm';
                  final int productId = item['ProductID'] ?? item['PRODUCTID'] ?? 0;
                  final String? imageUrl = item['ImageUrl'] ?? item['IMAGEURL'] ?? item['ImageURL'];

                  final double originalPrice = (item['Price'] ?? item['PRICE'] ?? item['originalPrice'] ?? 0.0).toDouble();
                  final double discountPrice = (item['DiscountPrice'] ?? item['DISCOUNTPRICE'] ?? item['discountPrice'] ?? originalPrice).toDouble();

                  final double actualOriginal = originalPrice > discountPrice ? originalPrice : 0;
                  final int discountPercent = actualOriginal > discountPrice
                      ? (((actualOriginal - discountPrice) / actualOriginal) * 100).round()
                      : 0;
                  final int quantity = (item['Quantity'] ?? item['QUANTITY'] ?? 1) as int;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(Icons.computer, size: 32, color: primaryAccent),
                              )
                            : const Icon(Icons.computer, size: 32, color: primaryAccent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.3, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mã SP: #$productId',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatCurrency(discountPrice),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: primaryColor,
                                      ),
                                    ),
                                    if (actualOriginal > discountPrice) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            formatCurrency(actualOriginal),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF94A3B8),
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: primaryLight,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '-$discountPercent%',
                                              style: const TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  'x$quantity',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 4. TÙY CHỌN BỔ SUNG
            _buildSectionHeader('Dịch vụ đi kèm', Icons.build_circle_rounded),
            Container(
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  SwitchListTile(
                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                    // 1. Màu khi BẬT (ON)
                    activeThumbColor: Colors.white, // Màu nút tròn khi bật
                    activeTrackColor: Color(0xFF1E40AF), // Màu thanh nền khi bật
                    // 2. Màu khi TẮT (OFF)
                    inactiveThumbColor: Colors.white, // Màu nút tròn khi tắt
                    inactiveTrackColor: Colors.grey[300], // Màu thanh nền khi tắt
                    title: const Text('Cài đặt phần mềm miễn phí', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                    subtitle: const Text('Hỗ trợ cài Win, Office cơ bản', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    value: installFree,
                    onChanged: (v) => setState(() => installFree = v),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  SwitchListTile(
                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                    // 1. Màu khi BẬT (ON)
                    activeThumbColor: Colors.white, // Màu nút tròn khi bật
                    activeTrackColor: Color(0xFF1E40AF), // Màu thanh nền khi bật
                    // 2. Màu khi TẮT (OFF)
                    inactiveThumbColor: Colors.white, // Màu nút tròn khi tắt
                    inactiveTrackColor: Colors.grey[300], // Màu thanh nền khi tắt
                    title: const Text('Hỗ trợ kỹ thuật (+55.000đ)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                    subtitle: const Text('Bảo hành tận nơi 12 tháng', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    value: techSupport,
                    onChanged: (v) => setState(() => techSupport = v),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  SwitchListTile(
                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                    // 1. Màu khi BẬT (ON)
                    activeThumbColor: Colors.white, // Màu nút tròn khi bật
                    activeTrackColor: Color(0xFF1E40AF), // Màu thanh nền khi bật
                    // 2. Màu khi TẮT (OFF)
                    inactiveThumbColor: Colors.white, // Màu nút tròn khi tắt
                    inactiveTrackColor: Colors.grey[300], // Màu thanh nền khi tắt
                    title: const Text('Xuất hóa đơn GTGT (VAT)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                    value: vatInvoice,
                    onChanged: (v) => setState(() => vatInvoice = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. TỔNG TIỀN TÍNH TOÁN
            _buildSectionHeader('Chi tiết thanh toán', Icons.receipt_long_rounded),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tạm tính', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Text(formatCurrency(subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phí vận chuyển', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Text(formatCurrency(shippingFee), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
                    ],
                  ),
                  if (techSupport) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hỗ trợ kỹ thuật', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        Text(formatCurrency(techSupportFee), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
                      ],
                    ),
                  ],
                  if (discount > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Giảm giá voucher', style: TextStyle(color: primaryAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('-${formatCurrency(discount)}', style: const TextStyle(color: primaryAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Colors.grey.shade200),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thành tiền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color.fromARGB(255, 28, 8, 212))),
                      Text(
                        formatCurrency(grandTotal),
                        style: const TextStyle(color: Color.fromARGB(255, 255, 0, 0), fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),

      // THANH THANH TOÁN DÍNH ĐÁY (STICKY BOTTOM BAR - NỀN TRẮNG XANH)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng thanh toán', style: TextStyle(fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(grandTotal),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 0, 0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 2,
                    shadowColor: primaryColor.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: checkoutItems.isEmpty
                      ? null
                      : () {
                          if (selectedPayment == null) {
                            setState(() {
                              showPaymentError = true;
                            });
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VNPAYQRScreen(
                                totalAmount: grandTotal,
                                bankName: selectedPayment!,
                                checkoutItems: checkoutItems,
                                recipientName: fullName,
                                recipientPhone: phone,
                                shippingAddress: address,
                                note: 'Giao giờ hành chính',
                              ),
                            ),
                          );
                        },
                  child: const Text(
                    'Thanh toán',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
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