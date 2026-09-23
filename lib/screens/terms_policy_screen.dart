import 'package:flutter/material.dart';

class TermsPolicyScreen extends StatelessWidget {
  const TermsPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E40AF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chính sách & Điều khoản',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Banner chào mừng / Giới thiệu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: primaryColor, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cam kết bảo vệ quyền lợi và thông tin người dùng tại MANB Shop.',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mục 1: Điều khoản sử dụng
            _buildSectionCard(
              icon: Icons.gavel,
              title: '1. Điều khoản sử dụng',
              content:
                  'Bằng việc truy cập và mua hàng tại ứng dụng, quý khách đồng ý tuân thủ các quy định về thanh toán, đặt hàng và bảo mật của hệ thống. Chúng tôi có quyền thay đổi nội dung điều khoản để phù hợp với quy định pháp luật.',
            ),

            // Mục 2: Chính sách bảo mật
            _buildSectionCard(
              icon: Icons.security,
              title: '2. Chính sách bảo mật',
              content:
                  'Thông tin cá nhân (họ tên, số điện thoại, địa chỉ) chỉ được sử dụng cho mục đích xử lý đơn hàng và hỗ trợ khách hàng. MANB Shop cam kết không chia sẻ dữ liệu người dùng cho bên thứ ba vì mục đích thương mại.',
            ),

            // Mục 3: Chính sách đổi trả & Hoàn tiền
            _buildSectionCard(
              icon: Icons.published_with_changes,
              title: '3. Đổi trả & Hoàn tiền',
              content:
                  'Hỗ trợ đổi trả sản phẩm trong vòng 7 ngày kể từ khi nhận hàng nếu có lỗi từ nhà sản xuất hoặc hư hỏng do vận chuyển. Sản phẩm phải còn nguyên tem mác, chưa qua sử dụng.',
            ),

            // Mục 4: Chính sách vận chuyển
            _buildSectionCard(
              icon: Icons.local_shipping,
              title: '4. Chính sách vận chuyển',
              content:
                  'Đơn hàng được giao từ 2 - 5 ngày làm việc tùy thuộc vào khu vực. Quý khách có quyền kiểm tra sản phẩm trước khi thanh toán cho nhân viên giao hàng (COD).',
            ),

            const SizedBox(height: 12),

            // Dòng thông tin cập nhật cuối
            const Text(
              'Cập nhật lần cuối: Tháng 09/2026',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1E40AF), size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.black,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}