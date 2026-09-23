import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import 'promotion_screen.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final Function(int)? onSelectTab;
  
  const CartScreen({super.key, this.onSelectTab});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Màu chủ đạo đồng bộ toàn bộ ứng dụng
  static const Color primaryColor = Color(0xFF1E40AF);

  String formatCurrency(dynamic price) {
    if (price == null) return '0 đ';
    int value = (price is double) ? price.round() : (price as int);
    String result = value.toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    result = result.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$result đ';
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    CartProvider cartProvider,
    int cartItemId,
    String productName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Xác nhận xóa',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa sản phẩm "$productName" khỏi giỏ hàng?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                bool success = await cartProvider.removeFromCart(cartItemId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Đã xóa sản phẩm khỏi giỏ hàng'
                            : 'Xóa thất bại, vui lòng thử lại!',
                      ),
                      backgroundColor: success ? Colors.black87 : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.cartItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Giỏ hàng (${cartProvider.totalItemsCount})',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cartProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : cartItems.isEmpty
              ? _buildEmptyState(context)
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final int cartItemId = item['ID'] ?? item['id'] ?? 0;
                          final String title =
                              item['ProductName'] ??
                              item['PRODUCTNAME'] ??
                              'Sản phẩm';
                          final int productId =
                              item['ProductID'] ?? item['PRODUCTID'] ?? 0;
                          final String? imageUrl =
                              item['ImageUrl'] ??
                              item['IMAGEURL'] ??
                              item['ImageURL'];

                          final double originalPrice = (item['Price'] ??
                                  item['PRICE'] ??
                                  item['originalPrice'] ??
                                  0.0)
                              .toDouble();
                          final double discountPrice = (item['DiscountPrice'] ??
                                  item['DISCOUNTPRICE'] ??
                                  item['discountPrice'] ??
                                  originalPrice)
                              .toDouble();

                          final double actualOriginal =
                              originalPrice > discountPrice ? originalPrice : 0;
                          final int discountPercent = actualOriginal > discountPrice
                              ? (((actualOriginal - discountPrice) /
                                          actualOriginal) *
                                      100)
                                  .round()
                              : 0;

                          final int quantity =
                              (item['Quantity'] ?? item['QUANTITY'] ?? 1) as int;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: imageUrl != null && imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.computer,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () =>
                                                _showDeleteConfirmationDialog(
                                              context,
                                              cartProvider,
                                              cartItemId,
                                              title,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(4.0),
                                              child: Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Mã SP: #$productId',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                formatCurrency(discountPrice),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: primaryColor,
                                                ),
                                              ),
                                              if (actualOriginal >
                                                  discountPrice) ...[
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Text(
                                                      formatCurrency(
                                                        actualOriginal,
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '-$discountPercent%',
                                                      style: const TextStyle(
                                                        color: Colors.redAccent,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                          Container(
                                            height: 32,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    if (quantity > 1) {
                                                      cartProvider.updateQuantity(
                                                        cartItemId,
                                                        quantity - 1,
                                                      );
                                                    } else {
                                                      _showDeleteConfirmationDialog(
                                                        context,
                                                        cartProvider,
                                                        cartItemId,
                                                        title,
                                                      );
                                                    }
                                                  },
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                    child: Icon(
                                                      Icons.remove,
                                                      size: 16,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                  ),
                                                  child: Text(
                                                    '$quantity',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    cartProvider.updateQuantity(
                                                      cartItemId,
                                                      quantity + 1,
                                                    );
                                                  },
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                    child: Icon(
                                                      Icons.add,
                                                      size: 16,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    _buildBottomCheckoutArea(context, cartProvider),
                  ],
                ),
    );
  }

  // Widget hiển thị giỏ hàng trống chuyên nghiệp
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Giỏ hàng của bạn đang trống',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy chọn những sản phẩm ưng ý để thêm vào giỏ hàng nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () {
              if (widget.onSelectTab != null) {
                widget.onSelectTab!(0); // 👈 Gọi nhảy sang Tab 0 (Trang chủ)
              } else {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text(
              'Khám phá sản phẩm',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị thanh tổng tiền và nút thanh toán bên dưới
  Widget _buildBottomCheckoutArea(
    BuildContext context,
    CartProvider cartProvider,
  ) {
    final bool hasVoucher = cartProvider.selectedVoucher != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PromotionScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Ưu đãi & Khuyến mãi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasVoucher
                          ? primaryColor.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hasVoucher ? 'ĐÃ CHỌN 1' : 'CHỌN MÃ',
                      style: TextStyle(
                        color: hasVoucher ? primaryColor : Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng thanh toán',
                      style: TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(cartProvider.totalAmount),
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  onPressed: cartProvider.cartItems.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutScreen(),
                            ),
                          );
                        },
                  child: const Text(
                    'Tiếp tục',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}