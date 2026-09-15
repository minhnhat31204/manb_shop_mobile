import 'package:flutter/material.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  bool isSelectBank = false;

  final List<String> banks = ['Vietcombank', 'BIDV', 'Techcombank'];

  // BẢNG MÀU CHỦ ĐẠO: XANH & TRẮNG
  static const Color primaryColor = Color(0xFF1E40AF); // Xanh dương đậm chủ đạo
  static const Color primaryAccent = Color(0xFF2563EB); // Xanh dương tươi
  static const Color primaryLight = Color(0xFFEFF6FF); // Xanh nhạt làm nền icon/box
  static const Color backgroundColor = Color(0xFFF8FAFC); // Nền xám xanh sáng

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          isSelectBank ? 'Chọn ngân hàng ATM' : 'Chọn hình thức thanh toán',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (isSelectBank) {
              setState(() => isSelectBank = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: !isSelectBank
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'PHƯƠNG THỨC KHẢ DỤNG',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_rounded, color: primaryColor, size: 22),
                        ),
                        title: const Text(
                          'ATM nội địa',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        subtitle: const Text(
                          'Thanh toán qua thẻ ATM / Thẻ ghi nợ nội địa',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 16),
                        onTap: () => setState(() => isSelectBank = true),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: primaryLight,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vui lòng chọn ngân hàng bạn đang sử dụng',
                          style: TextStyle(fontSize: 13, color: primaryColor.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: banks.length,
                    itemBuilder: (context, index) {
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            // Trả về tên ngân hàng được chọn
                            Navigator.pop(context, 'ATM nội địa (${banks[index]})');
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              banks[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}