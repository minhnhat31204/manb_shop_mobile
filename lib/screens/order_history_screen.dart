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

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context, listen: false).currentUserId;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Nền xám trắng nhạt
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D4ED8), // Xanh chủ đạo
          foregroundColor: Colors.white, // Chữ/Icon màu trắng
          elevation: 0,
          title: const Text('Quản lý đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          bottom: const TabBar(
            indicatorColor: Colors.white, // Đường gạch chân Tab màu trắng
            indicatorWeight: 3,
            labelColor: Colors.white, // Chữ tab đang chọn màu trắng
            unselectedLabelColor: Colors.white70, // Chữ tab chưa chọn màu trắng mờ
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
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1D4ED8)));
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
      
      // Ánh xạ trạng thái Tiếng Anh (API) và Tiếng Việt (UI)
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

        return Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(
              'Mã đơn: #${order['ORDERID'] ?? order['OrderID'] ?? order['orderId'] ?? order['ID']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  'Tổng tiền: ${formatCurrency(order['TOTALAMOUNT'] ?? order['TotalAmount'] ?? order['totalAmount'])}',
                  style: const TextStyle(color: Color.fromARGB(255, 255, 0, 0), fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phương thức: ${order['PAYMENTMETHOD'] ?? order['PaymentMethod'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF1D4ED8)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(order: order),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
}