import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';

class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key});

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  List<Map<String, dynamic>> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVouchers();
  }

  // Load danh sách Voucher từ API
  Future<void> _fetchVouchers() async {
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/vouchers'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _vouchers = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    return dateStr.split('T')[0]; // Lấy phần trước chữ 'T'
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final selectedVoucher = cartProvider.selectedVoucher;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã khuyến mãi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E40AF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _vouchers.length,
              itemBuilder: (context, index) {
                final voucher = _vouchers[index];
                final bool isSelected = selectedVoucher != null &&
                    selectedVoucher['VoucherID'] == voucher['VoucherID'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Image.network(
                      voucher['ImageUrl'] ?? 'https://via.placeholder.com/50',
                      width: 50,
                      height: 50,
                      errorBuilder: (_, _, _) => const Icon(Icons.local_offer, size: 40, color: Colors.blue),
                    ),
                    title: Text(voucher['Name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Giảm ${voucher['DiscountPercentage']}%\nHSD: ${formatDate(voucher['ExpiryDate'])}'),
                    trailing: Checkbox(
                      activeColor: const Color(0xFF1E40AF), // Màu tích xanh
                      value: isSelected,
                      onChanged: (bool? value) {
                        cartProvider.toggleVoucher(voucher);
                      },
                    ),
                    onTap: () {
                      cartProvider.toggleVoucher(voucher);
                    },
                  ),
                );
              },
            ),
    );
  }
}