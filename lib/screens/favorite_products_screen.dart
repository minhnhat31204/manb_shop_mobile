import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/user_provider.dart';
import 'product_detail_screen.dart';

class FavoriteProductsScreen extends StatefulWidget {
  const FavoriteProductsScreen({super.key});

  @override
  State<FavoriteProductsScreen> createState() => _FavoriteProductsScreenState();
}

class _FavoriteProductsScreenState extends State<FavoriteProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Provider.of<UserProvider>(context, listen: false).currentUserId;
      if (userId != null) {
        Provider.of<FavoriteProvider>(context, listen: false).loadFavorites(userId);
      }
    });
  }

  String _formatCurrency(num amount) {
    String str = amount.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  String _extractBrand(String productName) {
    if (productName.trim().isEmpty) return 'KHÔNG XÁC ĐỊNH';
    List<String> words = productName.trim().split(RegExp(r'\s+'));
    for (String word in words) {
      String cleanWord = word.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');
      if (cleanWord.isNotEmpty && RegExp(r'^[A-Z0-9]+$').hasMatch(cleanWord)) {
        return cleanWord;
      }
    }
    return words[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text(
          'Sản phẩm yêu thích',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer2<FavoriteProvider, UserProvider>(
        builder: (context, favProvider, userProvider, child) {
          final favorites = favProvider.favoriteProducts;
          final userId = userProvider.currentUserId;

          if (favorites.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có sản phẩm yêu thích nào.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.50,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final item = favorites[index];

              final String imageUrl =
                  item['ImageUrl'] ?? item['IMAGEURL'] ?? item['ImageURL'] ?? item['Image'] ?? '';
              final String productName =
                  item['ProductName'] ?? item['PRODUCTNAME'] ?? item['Name'] ?? 'Chưa có tên';

              final double originalPrice = (item['Price'] ?? item['PRICE'] ?? 0).toDouble();
              final double discountPrice = (item['DiscountPrice'] ??
                      item['DISCOUNTPRICE'] ??
                      (originalPrice > 0 ? originalPrice * 0.82 : 0))
                  .toDouble();

              final double discountAmount =
                  originalPrice > discountPrice ? originalPrice - discountPrice : 0;
              final int discountPercent = originalPrice > 0
                  ? ((discountAmount / originalPrice) * 100).round()
                  : 0;

              final String brandName = _extractBrand(productName);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(product: item),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFF0F0F0),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. KHUNG ẢNH + BADGE TIẾT KIỆM
                      Stack(
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.white,
                            padding: const EdgeInsets.all(8),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                  )
                                : const Icon(
                                    Icons.computer,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                          ),
                          if (discountAmount > 0)
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFF3B82F6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TIẾT KIỆM',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${_formatCurrency(discountAmount)} ',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: 'đ',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      // 2. PHÂN VÙNG NỘI DUNG
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  brandName,
                                  style: const TextStyle(
                                    color: Color(0xFF8C91A0),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    if (userId != null) {
                                      favProvider.toggleFavorite(item, userId);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Vui lòng đăng nhập để thực hiện thao tác!'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            Text(
                              productName,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF333333),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // GIÁ GIẢM
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${_formatCurrency(discountPrice)} ',
                                    style: const TextStyle(
                                      color: Color(0xFF1D4ED8),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'đ',
                                    style: TextStyle(
                                      color: Color(0xFF1D4ED8),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),

                            // GIÁ GỐC + PHẦN TRĂM GIẢM
                            if (originalPrice > discountPrice)
                              Row(
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${_formatCurrency(originalPrice)} ',
                                          style: const TextStyle(
                                            color: Color(0xFF9E9E9E),
                                            fontSize: 12,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: 'đ',
                                          style: TextStyle(
                                            color: Color(0xFF9E9E9E),
                                            fontSize: 12,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '-$discountPercent%',
                                    style: const TextStyle(
                                      color: Color(0xFFE53935),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}