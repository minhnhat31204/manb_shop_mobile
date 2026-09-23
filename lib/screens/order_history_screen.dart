import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  String formatCurrency(dynamic price) {
    if (price == null) return '0 đ';
    int value = (price is double) ? price.round() : (price as int);
    String result = value.toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return '${result.replaceAllMapped(reg, (Match m) => '${m[1]}.')} đ';
  }

  // Bổ trợ lấy URL hình ảnh linh hoạt hỗ trợ mọi kiểu cấu trúc API
  String? _getImageUrl(dynamic item) {
    if (item == null) return null;
    final product = item['Product'] ?? item['product'] ?? item;
    return product['ImageUrl'] ??
        product['IMAGEURL'] ??
        product['imageUrl'] ??
        product['Image'] ??
        product['IMAGE'] ??
        item['ImageUrl'] ??
        item['IMAGEURL'] ??
        item['imageUrl'] ??
        item['Image'];
  }

  // Widget hiển thị Thumbnail (1 ảnh hoặc 2 ảnh đè lên nhau)
  Widget _buildOrderThumbnail(List items) {
    const double size = 56.0;

    if (items.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
      );
    }

    // Trường hợp 1 sản phẩm: Hiển thị 1 ảnh duy nhất
    if (items.length == 1) {
      final String? imageUrl = _getImageUrl(items[0]);
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.computer, color: Colors.grey),
                ),
              )
            : const Icon(Icons.computer, color: Colors.grey),
      );
    }

    // Trường hợp từ 2 sản phẩm trở lên: Đè 2 ảnh lên nhau giống App mẫu Phong Vũ
    final String? img1 = _getImageUrl(items[0]);
    final String? img2 = _getImageUrl(items[1]);

    return SizedBox(
      width: size + 10,
      height: size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ảnh sản phẩm thứ 2 (nằm bên dưới/phía sau)
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: size - 8,
              height: size - 8,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: img2 != null && img2.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        img2,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(Icons.computer, size: 20, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.computer, size: 20, color: Colors.grey),
            ),
          ),
          // Ảnh sản phẩm thứ 1 (nằm đè lên trên)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size - 4,
              height: size - 4,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(-2, 2),
                  )
                ],
              ),
              child: img1 != null && img1.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        img1,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(Icons.computer, size: 24, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.computer, size: 24, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context, listen: false).currentUserId;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E40AF),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Quản lý đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Chờ xác nhận'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Đã giao'),
            ],
          ),
        ),
        body: userId == null
            ? const Center(child: Text('Vui lòng đăng nhập để xem đơn hàng'))
            : FutureBuilder<List<dynamic>>(
                future: ApiService.getOrdersByUserId(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)));
                  }
                  final orders = snapshot.data ?? [];
                  return TabBarView(
                    children: [
                      _buildOrderList(orders, 'Chờ xác nhận'),
                      _buildOrderList(orders, 'Đang giao'),
                      _buildOrderList(orders, 'Đã giao'),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, String targetStatus) {
    final filtered = orders.where((o) {
      final rawStatus = (o['STATUS'] ?? o['Status'] ?? o['status'] ?? '').toString().trim().toLowerCase();
      
      if (targetStatus == 'Chờ xác nhận') {
        return rawStatus == 'pending' || rawStatus == 'chờ xác nhận';
      } else if (targetStatus == 'Đang giao') {
        return rawStatus == 'shipping' || rawStatus == 'delivering' || rawStatus == 'đang giao';
      } else if (targetStatus == 'Đã giao') {
        return rawStatus == 'completed' || rawStatus == 'delivered' || rawStatus == 'đã giao';
      }
      return false;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('Không có đơn hàng nào', style: TextStyle(color: Colors.grey, fontSize: 15)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final order = filtered[index];
        
        // BỔ SUNG THÊM KEY order['Items']
        final List items = order['Items'] ?? order['ITEMS'] ?? order['items'] ?? order['OrderItems'] ?? [];
        
        // Lấy tên sản phẩm đại diện
        String firstProductName = 'Đơn hàng #${order['ORDERID'] ?? order['OrderID'] ?? order['ID']}';
        if (items.isNotEmpty) {
          final firstProduct = items[0]['Product'] ?? items[0]['product'] ?? items[0];
          firstProductName = firstProduct['ProductName'] ?? 
                             firstProduct['PRODUCTNAME'] ?? 
                             firstProduct['Name'] ?? 
                             items[0]['ProductName'] ?? 
                             firstProductName;
        }

        return Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(order: order),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mã đơn: ${order['ORDERID'] ?? order['OrderID'] ?? order['ID']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Text(
                          targetStatus.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderThumbnail(items),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstProductName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatCurrency(order['TOTALAMOUNT'] ?? order['TotalAmount'] ?? order['totalAmount']),
                              style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
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
  }
}