import 'package:flutter/material.dart';
import 'product_detail_screen.dart'; 
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final dynamic order;

  const OrderDetailScreen({super.key, required this.order});

  String formatCurrency(dynamic price) {
    if (price == null) return '0 đ';
    int value = (price is double) ? price.round() : (price as int);
    String result = value.toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return '${result.replaceAllMapped(reg, (Match m) => '${m[1]}.')} đ';
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '---';
    try {
      DateTime parsedDate = DateTime.parse(dateStr).toLocal();
      return DateFormat('HH:mm - dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusVN(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending':
      return 'Chờ xác nhận';
    case 'shipping':
    case 'delivering':
      return 'Đang giao';
    case 'completed':
    case 'delivered':
      return 'Đã giao';
    case 'cancelled':
    case 'canceled':
      return 'Đã hủy';
    default:
      return status; // Trả về giá trị gốc nếu không khớp
  }
}

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = order['items'] ?? order['OrderItems'] ?? order['ORDERITEMS'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF), // Xanh chủ đạo
        foregroundColor: Colors.white, // Icon back + tiêu đề màu trắng
        elevation: 0,
        title: Text(
          'Chi tiết đơn hàng #${order['ORDERID'] ?? order['OrderID'] ?? order['ID']}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. THÔNG TIN ĐƠN HÀNG
            const Text('Thông tin đơn hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildRow('Mã đơn hàng:', '#${order['ORDERID'] ?? order['OrderID'] ?? order['ID']}'),
                    _buildRow('Ngày đặt:', formatDate(order['ORDERDATE'] ?? order['OrderDate'])),
                    _buildRow('Trạng thái:', _getStatusVN((order['STATUS'] ?? order['Status'] ?? 'Pending').toString())),
                    _buildRow('Phương thức TT:', '${order['PAYMENTMETHOD'] ?? order['PaymentMethod'] ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. THÔNG TIN GIAO HÀNG
            const Text('Thông tin giao hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildRow('Người nhận:', '${order['RECIPIENTNAME'] ?? order['RecipientName'] ?? 'Chưa cập nhật'}'),
                    _buildRow('Số điện thoại:', '${order['RECIPIENTPHONE'] ?? order['RecipientPhone'] ?? 'Chưa cập nhật'}'),
                    _buildRow('Địa chỉ:', '${order['SHIPPINGADDRESS'] ?? order['ShippingAddress'] ?? 'Chưa cập nhật'}'),
                    _buildRow('Ghi chú:', '${order['NOTE'] ?? order['Note'] ?? 'Không có'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. DANH SÁCH SẢN PHẨM
            const Text('Sản phẩm đã mua', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
            const SizedBox(height: 8),
            items.isEmpty
              ? const Text('Không có chi tiết sản phẩm.', style: TextStyle(color: Colors.grey))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final product = item['Product'] ?? item['product'] ?? {};
                    final String name = product['ProductName'] ?? item['ProductName'] ?? 'Sản phẩm #${item['ProductID'] ?? item['PRODUCTID']}';
                    final dynamic price = item['UnitPrice'] ?? item['UNITPRICE'] ?? item['Price'] ?? product['Price'] ?? 0;
                    final dynamic rawOriginal = product['Price'] ?? product['PRICE'] ?? product['OriginalPrice'] ?? product['ORIGINALPRICE'];
                    final double originalPrice = (rawOriginal != null) ? (rawOriginal as num).toDouble() : 0.0;
                    final double currentPrice = (price as num).toDouble();

                    final int discountPercent = (originalPrice > currentPrice && originalPrice > 0)
                        ? (((originalPrice - currentPrice) / originalPrice) * 100).round()
                        : (product['DiscountPercent'] ?? product['DISCOUNTPERCENT'] ?? 0);

                    final String? imageUrl = product['Image'] ?? product['IMAGE'] ?? product['ImageUrl'] ?? product['IMAGEURL'] ?? item['imageUrl'];
                    final int qty = item['Quantity'] ?? item['QUANTITY'] ?? item['quantity'] ?? 1;

                    return Card(
                      color: Colors.white,
                      elevation: 0.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          // Ưu tiên lấy object product, nếu không có thì gộp từ item chính
                          final Map<String, dynamic> targetProduct = 
                              (product != null && product.isNotEmpty) 
                                  ? Map<String, dynamic>.from(product)
                                  : Map<String, dynamic>.from(item);

                          final int orderId = order['ORDERID'] ?? order['OrderID'] ?? order['ID'] ?? 0;
                          final String orderStatus = (order['STATUS'] ?? order['Status'] ?? '').toString();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                product: targetProduct,
                                fromOrderId: orderId,       
                                orderStatus: orderStatus,   
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              Container(
                                width: 65,
                                height: 65,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(imageUrl, fit: BoxFit.cover),
                                      )
                                    : const Icon(Icons.computer, size: 32, color: Color(0xFF1E40AF)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Số lượng: x$qty', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatCurrency(currentPrice),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E40AF)),
                                  ),
                                  if (originalPrice > currentPrice) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          formatCurrency(originalPrice),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                        if (discountPercent > 0) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '-$discountPercent%',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            const SizedBox(height: 16),

            // 4. TỔNG TIỀN
            Divider(color: Colors.grey.shade300),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  formatCurrency(order['TOTALAMOUNT'] ?? order['TotalAmount'] ?? order['totalAmount']),
                  style: const TextStyle(fontSize: 18, color: Color.fromARGB(255, 255, 0, 0), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}