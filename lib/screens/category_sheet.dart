import 'package:flutter/material.dart';

class CategoryBottomSheetContent extends StatefulWidget {
  final Function(String) onSelectSubCategory;
  final VoidCallback onClose; // Thêm callback đóng

  const CategoryBottomSheetContent({
    super.key, 
    required this.onSelectSubCategory,
    required this.onClose,
  });

  @override
  State<CategoryBottomSheetContent> createState() => _CategoryBottomSheetContentState();
}

class _CategoryBottomSheetContentState extends State<CategoryBottomSheetContent> {
  int selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Laptop',
      'imageUrl': 'https://lh3.googleusercontent.com/rKgLP16Si8TpmMie9Nr4pZAX11NgPCJGYWYKpuzd6jga5QMesCZPz4PSSdMNY0b6_lCPdk38o6PCF6k1Wx_Tbh46vUfe8nIJ2g=w180-rw',
      'brands': ['Acer', 'Dell', 'HP', 'Lenovo', 'MSI'],
      'needs': ['Laptop Gaming', 'Laptop AI', 'Laptop đồ họa'],
    },
    // {
    //   'name': 'Sản phẩm Apple',
    //   'imageUrl': '',
    //   'icon': Icons.apple,
    //   'brands': ['MacBook', 'iPhone', 'iPad', 'Apple Watch'],
    //   'needs': ['Học tập', 'Làm việc', 'Giải trí'],
    // },
    // {
    //   'name': 'PC - Máy tính bàn',
    //   'imageUrl': '',
    //   'icon': Icons.desktop_windows,
    //   'brands': ['PC Gaming', 'PC Văn phòng', 'PC Workstation'],
    //   'needs': ['Chơi game', 'Đồ họa', 'Văn phòng'],
    // },
  ];

  @override
  Widget build(BuildContext context) {
    final currentCategory = categories[selectedCategoryIndex];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              const Text(
                'Danh mục sản phẩm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: widget.onClose, // Gọi callback đóng
                child: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = selectedCategoryIndex == index;
                    final category = categories[index];
                    final String imageUrl = category['imageUrl'] ?? '';

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryIndex = index;
                        });
                      },
                      child: Container(
                        color: isSelected ? Colors.white : const Color(0xFFF5F5F5),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFE8F0FE) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected ? Border.all(color: Colors.blue, width: 1.5) : null,
                              ),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => Icon(
                                        category['icon'] ?? Icons.category,
                                        color: Colors.blue.shade800,
                                      ),
                                    )
                                  : Icon(
                                      category['icon'] ?? Icons.category,
                                      color: isSelected ? Colors.blue.shade800 : Colors.grey,
                                      size: 28,
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              category['name'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.blue.shade800 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentCategory['name'].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Thương hiệu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    _buildGridButtons(currentCategory['brands']),
                    const SizedBox(height: 16),
                    const Text('Nhu cầu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    _buildGridButtons(currentCategory['needs']),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridButtons(List<String> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.zero,
          ),
          onPressed: () {
            widget.onSelectSubCategory(items[index]);
          },
          child: Text(
            items[index],
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        );
      },
    );
  }
}