import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/favorite_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'login_options_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int? fromOrderId;
  final String? orderStatus;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.fromOrderId,
    this.orderStatus,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _quantity = 1;
  final String _selectedColor = 'Mặc định';
  List<Map<String, dynamic>> _relatedProducts = [];
  bool _canUserReview = false;
  bool _isCheckingReview = true;
  int _selectedRating = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRelatedProducts();

    // Kiểm tra quyền đánh giá khi vào từ trang Chi tiết hóa đơn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkReviewEligibility();
    });
  }

  Future<void> _checkReviewEligibility() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.currentUserId;

    // Lấy ProductID an toàn hơn từ Map product
    final dynamic rawProductId =
        widget.product['ProductID'] ??
        widget.product['PRODUCTID'] ??
        widget.product['id'] ??
        widget.product['ID'];

    final status = widget.orderStatus?.toLowerCase() ?? '';

    if (widget.fromOrderId != null &&
        userId != null &&
        rawProductId != null &&
        (status == 'completed' ||
            status == 'delivered' ||
            status == 'đã giao')) {
      final int productId = (rawProductId is int)
          ? rawProductId
          : int.parse(rawProductId.toString());

      bool canReview = await ApiService.checkCanReview(
        widget.fromOrderId!,
        productId,
        userId,
      );
      if (mounted) {
        setState(() {
          _canUserReview = canReview;
          _isCheckingReview = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isCheckingReview = false);
      }
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung đánh giá!')),
      );
      return;
    }

    // 1. Kiểm tra từ OrderID
    if (widget.fromOrderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin đơn hàng để đánh giá!'),
        ),
      );
      return;
    }

    final userId = Provider.of<UserProvider>(
      context,
      listen: false,
    ).currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để thực hiện đánh giá!'),
        ),
      );
      return;
    }

    // 2. Lấy productId an toàn với nhiều trường hợp tên key
    final dynamic rawProductId =
        widget.product['ProductID'] ??
        widget.product['PRODUCTID'] ??
        widget.product['id'] ??
        widget.product['Id'] ??
        widget.product['ID'];

    if (rawProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không lấy được ID sản phẩm!')),
      );
      return;
    }

    final int productId = (rawProductId is int)
        ? rawProductId
        : int.parse(rawProductId.toString());

    setState(() => _isSubmittingReview = true);

    try {
      bool success = await ApiService.submitReview(
        orderId: widget.fromOrderId!,
        productId: productId,
        userId: userId,
        rating: _selectedRating,
        comment: _reviewController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmittingReview = false);
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đánh giá thành công!')));
          setState(() {
            _canUserReview = false; // Khóa không cho đánh giá tiếp
            _reviewController.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gửi đánh giá thất bại, vui lòng thử lại!'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Lỗi gửi đánh giá: $e");
      if (mounted) {
        setState(() => _isSubmittingReview = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Có lỗi xảy ra: $e')));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Hàm hỗ trợ ép kiểu số an toàn chống văng app
  double _toDouble(dynamic val, double fallback) {
    if (val == null) return fallback;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? fallback;
    return fallback;
  }

  // Lấy dữ liệu danh sách sản phẩm liên quan từ Database
  Future<void> _fetchRelatedProducts() async {
    final String productName = widget.product['ProductName'] ?? widget.product['PRODUCTNAME'] ?? '';
    final String currentBrand = (widget.product['Brand'] != null && widget.product['Brand'].toString().isNotEmpty)
        ? widget.product['Brand']
        : extractBrand(productName);
    final dynamic currentId =
        widget.product['ProductID'] ?? widget.product['PRODUCTID'] ?? 0;

    if (currentBrand.toString().isEmpty) return;

    try {
      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/products?brand=$currentBrand'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _relatedProducts = List<Map<String, dynamic>>.from(data)
              .where(
                (item) => (item['ProductID'] ?? item['PRODUCTID']) != currentId,
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải sản phẩm liên quan: $e");
    }
  }

  // Mở ứng dụng gọi điện tới số 0909680426
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      // Thử mở trực tiếp app gọi điện
      final bool launched = await launchUrl(launchUri);
      if (!launched) {
        debugPrint('Không thể thực hiện cuộc gọi đến $phoneNumber');
      }
    } catch (e) {
      debugPrint('Lỗi mở ứng dụng gọi điện: $e');
    }
  }

  String formatCurrency(num amount) {
    String str = amount.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> p = widget.product;

    // Lấy dữ liệu thực tế từ Database
    final String category = p['CategoryName'] ?? p['CATEGORYNAME'] ?? 'Laptop';
    final String productName = p['ProductName'] ?? p['PRODUCTNAME'] ?? '';
    final String brand = (p['Brand'] != null && p['Brand'].toString().isNotEmpty)
    ? p['Brand']
    : extractBrand(productName);
    final String rating = (p['Rating'] ?? p['RATING'] ?? '0').toString();
    final String imageUrl =
        p['ImageUrl'] ?? p['IMAGEURL'] ?? p['ImageURL'] ?? '';

    final double originalPrice = _toDouble(p['Price'] ?? p['PRICE'], 0.0);
    final double discountPrice = _toDouble(
      p['DiscountPrice'] ?? p['DISCOUNTPRICE'] ?? p['Price'] ?? p['PRICE'],
      0.0,
    );

    final int discountPercent =
        (originalPrice > discountPrice && originalPrice > 0)
        ? (((originalPrice - discountPrice) / originalPrice) * 100).round()
        : _toDouble(p['DiscountPercent'] ?? p['DISCOUNTPERCENT'], 0.0).round();

    final String description =
        p['Description'] ?? p['DESCRIPTION'] ?? 'Chưa có mô tả chi tiết.';
    Map<String, dynamic> specDetails = {};
    final rawSpecs = p['Specifications'] ?? p['SPECIFICATIONS'];

    if (rawSpecs is Map<String, dynamic>) {
      specDetails = rawSpecs;
    } else if (rawSpecs is String && rawSpecs.isNotEmpty) {
      try {
        specDetails = jsonDecode(rawSpecs) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Lỗi parse Specifications JSON: $e');
      }
    }

    List<String> images = imageUrl.isNotEmpty ? [imageUrl] : [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 64, 214),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(221, 255, 255, 255),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: Color.fromARGB(221, 250, 250, 250),
            ),
            onPressed: () {},
          ),
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              final count = cart.totalItemsCount;
              return IconButton(
                icon: Badge(
                  label: Text('$count'),
                  isLabelVisible: count > 0,
                  backgroundColor: const Color.fromARGB(255, 233, 1, 1),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Color.fromARGB(221, 255, 255, 255),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.more_horiz,
              color: Color.fromARGB(221, 250, 250, 250),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBreadcrumb(category, brand, productName),
                      _buildImageGallery(images, imageUrl),
                      _buildProductTitleSection(brand, productName),
                      _buildRatingSection(rating),
                      _buildPriceSection(
                        discountPrice,
                        originalPrice,
                        discountPercent,
                      ),
                      _buildExtraVouchersSection(),
                      _buildPromotionsSection(),
                      _buildPaymentOffersSection(),
                      _buildHighlightsSection(p, specDetails),
                      _buildSalesPoliciesSection(),
                      _buildDetailTabsSection(specDetails, description),
                      if (_relatedProducts.isNotEmpty)
                        _buildRelatedProductsSection(brand),

                      _buildReviewsSection(rating),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              _buildBottomActionBar(p),
            ],
          ),
          // Nút gọi điện thoại chuyển hướng gọi đến 0909680426
          Positioned(
            right: 16,
            bottom: 130,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF1E40AF),
              heroTag: null,
              onPressed: () => _makePhoneCall('0909680426'),
              child: const Icon(Icons.call, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(String category, String brand, String productName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 1. Nút Trang chủ -> Quay về màn hình chính
            GestureDetector(
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Row(
                children: [
                  Icon(Icons.home, size: 16, color: Color(0xFF1E40AF)),
                  SizedBox(width: 4),
                  Text(
                    'Trang chủ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              '  >  ',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            // 2. Nút Danh mục (VD: Laptop)
            GestureDetector(
              onTap: () {
                // Chuyển hướng tới danh sách tất cả Laptop
                // Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListScreen(category: category)));
                debugPrint("Điều hướng tới danh mục: $category");
              },
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Text(
              '  >  ',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            // 3. Nút Thương hiệu (VD: Laptop HP)
            GestureDetector(
              onTap: () {
                // Chuyển hướng tới danh sách sản phẩm lọc theo Thương hiệu
                // Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListScreen(brand: brand)));
                debugPrint("Điều hướng tới thương hiệu: $brand");
              },
              child: Text(
                '$category $brand',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Text(
              '  >  ',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            // 4. Tên sản phẩm hiện tại (không bấm)
            Text(
              productName.length > 15
                  ? '${productName.substring(0, 15)}...'
                  : productName,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> images, String mainImage) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          height: 220,
          child: mainImage.isNotEmpty
              ? Image.network(
                  mainImage,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.computer, size: 120, color: Colors.grey),
                )
              : const Icon(Icons.computer, size: 120, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildProductTitleSection(String brand, String productName) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Thương hiệu: ',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              Text(
                brand,
                style: const TextStyle(
                  color: Color(0xFF1E40AF),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
              Consumer2<FavoriteProvider, UserProvider>(
                builder: (context, favProvider, userProvider, child) {
                  final userId = userProvider.currentUserId; // Lấy ID chuẩn
                  final isFav = favProvider.isFavorite(widget.product);

                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Color(0xFF1E40AF) : const Color(0xFF1E40AF),
                    ),
                    onPressed: () {
                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vui lòng đăng nhập để yêu thích sản phẩm!',
                            ),
                          ),
                        );
                        return;
                      }

                      favProvider.toggleFavorite(widget.product, userId);
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Đã bỏ phần SKU và chỉ hiển thị Rating từ Database
  Widget _buildRatingSection(String rating) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 16),
          Text(
            ' $rating (Đánh giá)',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(
    double discountPrice,
    double originalPrice,
    int discountPercent,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (originalPrice > discountPrice && originalPrice > 0)
            Row(
              children: [
                Text(
                  '${formatCurrency(originalPrice)} đ',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                if (discountPercent > 0)
                  Text(
                    '-$discountPercent%',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          Text(
            '${formatCurrency(discountPrice)} đ',
            style: const TextStyle(
              color: Color(0xFF1E40AF),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Phần Bạn sẽ nhận được (Giữ nguyên tĩnh)
  Widget _buildExtraVouchersSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFF0F5FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Bạn sẽ nhận được',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildBulletText(
            '1x Mã giảm thêm 200.000đ cho một số phần mềm Microsoft M365 Personal, M365 Family',
          ),
          _buildBulletText(
            '1x Mã giảm 200.000đ cho một số sản phẩm chuột, bàn phím, tai nghe Logitech',
          ),
          _buildBulletText(
            '1x Mã giảm thêm 300.000 cho đơn từ 700.000 các sản phẩm Phụ kiện, chuột, bàn phím, tai nghe, màn hình, hàng gia dụng',
          ),
        ],
      ),
    );
  }

  // Phần Chọn 1 trong những khuyến mãi sau & Khuyến mãi liên quan (Giữ nguyên tĩnh)
  Widget _buildPromotionsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn 1 trong những khuyến mãi sau:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1E40AF)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.card_giftcard, color: Color(0xFF1E40AF)),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giảm 1.200.000đ (áp dụng vào giá sản phẩm)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Khuyến mãi áp dụng khi mua đủ 1 sản phẩm, mua tối thiểu 1 sản phẩm',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        'HSD: 30/9/2026',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: Color(0xFF1E40AF)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Khuyến mãi liên quan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          _buildBulletText(
            'Nhập mã PVHPBQ260701 tặng 1 Túi đeo lưng/ Balo laptop Targus 15.6 TSB883 Black (Safire) trị giá 900.000đ cho đơn hàng có sản phẩm này',
          ),
          _buildBulletText(
            'Đổi Điểm Thi THPT: Voucher đến 5 triệu hoặc Quà tặng AirPods 4. Xem chi tiết',
          ),
          _buildBulletText(
            'Phụ kiện xịn giảm đến 30% khi mua kèm PC/Laptop/Macbook. Xem chi tiết',
          ),
          _buildBulletText(
            'Học sinh, Sinh viên, Giáo viên, Giảng viên giảm thêm...',
          ),
        ],
      ),
    );
  }

  // Phần Ưu đãi thanh toán (Giữ nguyên tĩnh)
  Widget _buildPaymentOffersSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ưu đãi thanh toán',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Image.network(
                'https://via.placeholder.com/60x20?text=TPBank',
                height: 20,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.credit_card, size: 20),
              ),
              const SizedBox(width: 15),
              Image.network(
                'https://via.placeholder.com/60x20?text=VNPAY',
                height: 20,
                errorBuilder: (_, _, _) => const Icon(Icons.payment, size: 20),
              ),
              const SizedBox(width: 15),
              Image.network(
                'https://via.placeholder.com/60x20?text=VIB',
                height: 20,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.credit_card, size: 20),
              ),
            ],
          ),
          const Divider(height: 16),
          RichText(
            text: const TextSpan(
              text:
                  'Giảm đến 800.000đ khi mở thẻ và thanh toán qua TPBank EVO. ',
              style: TextStyle(color: Colors.black87, fontSize: 12),
              children: [
                TextSpan(
                  text: 'Xem chi tiết',
                  style: TextStyle(color: Color(0xFF1E40AF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Phần Chính sách bán hàng & Dịch vụ khác (Giữ nguyên tĩnh)
  Widget _buildSalesPoliciesSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chính sách bán hàng',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildPolicyRow(
            Icons.local_shipping_outlined,
            'Miễn phí giao hàng cho đơn hàng từ 5 triệu',
            'Xem chi tiết',
          ),
          _buildPolicyRow(
            Icons.published_with_changes_outlined,
            'Đổi trả trong vòng 10 ngày',
            'Xem chi tiết',
          ),
          _buildPolicyRow(
            Icons.verified_outlined,
            'Cam kết hàng chính hãng 100%',
            null,
          ),
          const SizedBox(height: 12),
          const Text(
            'Dịch vụ khác',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildPolicyRow(
            Icons.build_outlined,
            'Gói dịch vụ bảo hành/ Sửa chữa tận nơi',
            'Xem chi tiết',
          ),
        ],
      ),
    );
  }

  // Khai báo biến quản lý trạng thái mở rộng ở đầu class _ProductDetailScreenState:
  bool _isExpandedSpecs = false;

  // Thay thế hàm _buildDetailTabsSection cũ bằng hàm dưới đây:
  Widget _buildDetailTabsSection(
    Map<String, dynamic> specs,
    String description,
  ) {
    final String productName =
        widget.product['ProductName'] ?? widget.product['PRODUCTNAME'] ?? '';

    // Đồng bộ logic lấy Thương hiệu y chang hình 2 và hình 3
    final String brand = (widget.product['Brand'] != null &&
            widget.product['Brand'].toString().isNotEmpty)
        ? widget.product['Brand']
        : extractBrand(productName);

    final String warranty =
        widget.product['Warranty'] ?? widget.product['WARRANTY'] ?? '12 tháng';
    final String series =
        widget.product['Series'] ?? widget.product['SERIES'] ?? brand;
    final String partNumber =
        widget.product['PartNumber'] ??
        widget.product['PARTNUMBER'] ??
        widget.product['SKU'] ??
        'BQ5B3PT';

    // Gom toàn bộ thông số vào Map
    final Map<String, String> displaySpecs = {
      'Thương hiệu': brand,
      'Bảo hành': warranty,
      'Series model': series,
      'Tên': productName,
      'Part-number': partNumber,
    };

    // Nối thêm các thông số kỹ thuật khác từ Database vào bảng
    specs.forEach((key, value) {
      if (value != null && !key.toString().toLowerCase().contains('price')) {
        displaySpecs[key.toString()] = value.toString();
      }
    });

    final entries = displaySpecs.entries.toList();
    final int visibleCount = _isExpandedSpecs ? entries.length : 5;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1E40AF),
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'Chi tiết sản phẩm'),
              Tab(text: 'Mô tả chi tiết'),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Nội dung của Tab
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              if (_tabController.index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ...List.generate(
                        visibleCount < entries.length
                            ? visibleCount
                            : entries.length,
                        (index) {
                          final isEven = index % 2 == 0;
                          return Container(
                            color: isEven
                                ? Colors.white
                                : const Color(0xFFF9FAFB),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 130,
                                  child: Text(
                                    entries[index].key,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entries[index].value,
                                    style: TextStyle(
                                      fontSize: 13,
                                      // Bổ sung style màu xanh và font đậm nếu là dòng Thương hiệu
                                      color: entries[index].key == 'Thương hiệu'
                                          ? const Color.fromARGB(255, 0, 0, 0)
                                          : const Color.fromARGB(221, 0, 0, 0),
                                      fontWeight: entries[index].key == 'Thương hiệu'
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (entries.length > 5)
                        Center(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: const StadiumBorder(),
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _isExpandedSpecs = !_isExpandedSpecs;
                              });
                            },
                            child: Text(
                              _isExpandedSpecs ? 'Thu gọn' : 'Xem thêm',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Các sản phẩm liên quan từ Database
  Widget _buildRelatedProductsSection(String brand) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              'Sản phẩm liên quan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 380,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _relatedProducts.length,
              itemBuilder: (context, index) {
                final item = _relatedProducts[index];
                final String relName =
                    item['ProductName'] ?? item['PRODUCTNAME'] ?? '';
                final String relImg =
                    item['ImageUrl'] ?? item['IMAGEURL'] ?? '';
                final String relBrand = item['Brand'] ?? item['BRAND'] ?? brand;

                final double origPrice = _toDouble(
                  item['Price'] ?? item['PRICE'],
                  0.0,
                );
                final double discPrice = _toDouble(
                  item['DiscountPrice'] ??
                      item['DISCOUNTPRICE'] ??
                      item['Price'],
                  0.0,
                );

                final int discountPercent =
                    origPrice > discPrice && origPrice > 0
                    ? (((origPrice - discPrice) / origPrice) * 100).round()
                    : 0;

                final String cpu = item['CPU'] ?? item['cpu'] ?? 'i9-13900H';
                final String gpu =
                    item['GPU'] ?? item['gpu'] ?? 'Intel Graphics';
                final String ram = item['RAM'] ?? item['ram'] ?? '16GB';
                final String ssd =
                    item['Storage'] ?? item['storage'] ?? '512GB';
                final String weight =
                    item['Weight'] ?? item['weight'] ?? '1.7 kg';
                final String display =
                    item['Display'] ??
                    item['display'] ??
                    '15.6" Full HD/ IPS/ 60Hz';

                return GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: item),
                      ),
                    );
                  },
                  child: Container(
                    width: 175,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              child: Container(
                                height: 120,
                                width: double.infinity,
                                color: Colors.white,
                                child: relImg.isNotEmpty
                                    ? Image.network(
                                        relImg,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.computer,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.computer,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            if (discountPercent > 0)
                              Positioned(
                                left: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6366F1),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                  child: Text(
                                    'TIẾT KIỆM ${formatCurrency(origPrice - discPrice)} đ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                relBrand.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(
                                Icons.favorite_border,
                                size: 18,
                                color: Color(0xFF1E40AF),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.0,
                          ),
                          child: Text(
                            relName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF1E40AF),
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'COMBO GIẢM ~ 50.000 đ',
                              style: TextStyle(
                                color: Color(0xFF1E40AF),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '${formatCurrency(discPrice)} đ',
                            style: const TextStyle(
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (origPrice > discPrice)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${formatCurrency(origPrice)} đ',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '-$discountPercent%',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSpecItem(Icons.developer_board, cpu),
                                _buildSpecItem(Icons.memory, gpu),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSpecItem(Icons.sd_card, ram),
                                    ),
                                    Expanded(
                                      child: _buildSpecItem(Icons.storage, ssd),
                                    ),
                                  ],
                                ),
                                _buildSpecItem(Icons.scale, weight),
                                _buildSpecItem(Icons.aspect_ratio, display),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSpecItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 10, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        '• $text',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildPolicyRow(IconData icon, String text, String? detailText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E40AF), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
          if (detailText != null)
            Text(
              detailText,
              style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecRowTable(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(Map<String, dynamic> product) {
    return Consumer2<UserProvider, CartProvider>(
      builder: (context, userProvider, cartProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Image.network(
                    product['ImageUrl'] ??
                        product['IMAGEURL'] ??
                        'https://via.placeholder.com/40',
                    height: 30,
                    width: 30,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.laptop, size: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['ProductName'] ??
                              product['PRODUCTNAME'] ??
                              '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Phân loại: $_selectedColor',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 14),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 14),
                          onPressed: () => setState(() => _quantity++),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E40AF)),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: () async {
                      if (!userProvider.isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginOptionsScreen(),
                          ),
                        );
                        return;
                      }
                      bool success = await cartProvider.addToCart(
                        product,
                        _quantity,
                      );
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã thêm sản phẩm vào giỏ hàng!'),
                          ),
                        );
                      }
                    },
                    child: const Icon(
                      Icons.add_shopping_cart,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        if (!userProvider.isLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginOptionsScreen(),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                              directBuyItem: {
                                ...product,
                                'Quantity': _quantity,
                              },
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'MUA NGAY',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Phần Đặc điểm nổi bật (Lấy thông tin tóm tắt từ Database)
  Widget _buildHighlightsSection(
    Map<String, dynamic> p,
    Map<String, dynamic> specs,
  ) {
    // Lấy dữ liệu động từ Database hoặc specs, nếu không có sẽ lấy giá trị mặc định từ sản phẩm
    final String cpu =
        specs['CPU'] ?? specs['cpu'] ?? p['CPU'] ?? p['cpu'] ?? 'Đang cập nhật';
    final String ram =
        specs['RAM'] ?? specs['ram'] ?? p['RAM'] ?? p['ram'] ?? 'Đang cập nhật';
    final String storage =
        specs['Ổ cứng'] ??
        specs['Storage'] ??
        p['Storage'] ??
        p['storage'] ??
        'Đang cập nhật';
    final String display =
        specs['Màn hình'] ??
        specs['Display'] ??
        p['Display'] ??
        p['display'] ??
        'Đang cập nhật';
    final String os =
        specs['Hệ điều hành'] ??
        specs['OS'] ??
        p['OS'] ??
        p['os'] ??
        'Đang cập nhật';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đặc điểm nổi bật',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              GestureDetector(
                onTap: () {
                  // Chuyển sang Tab chi tiết khi bấm "Xem thông tin chi tiết"
                  _tabController.animateTo(0);
                },
                child: const Text(
                  'Xem thông tin chi tiết',
                  style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildHighlightItem('CPU', cpu),
          _buildHighlightItem('RAM', ram),
          _buildHighlightItem('Ổ cứng', storage),
          _buildHighlightItem('Màn hình', display),
          _buildHighlightItem('OS', os),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildReviewsSection(String rating) {
    final dynamic productId =
        widget.product['ProductID'] ?? widget.product['PRODUCTID'];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đánh giá & Bình luận',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 12),

          // Tổng quan Rating
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Text(
                  rating,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Đánh giá từ khách hàng đã mua hàng',
                      style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Khung gửi đánh giá (Chỉ hiển thị khi đủ điều kiện: completed + chưa đánh giá)
          if (_canUserReview) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E40AF), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đánh giá của bạn cho sản phẩm này:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: _reviewController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Hãy chia sẻ trải nghiệm của bạn về sản phẩm...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDBEAFE)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1E40AF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: _isSubmittingReview ? null : _submitReview,
                      child: _isSubmittingReview
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Gửi Đánh Giá',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 28),

          // Danh sách các đánh giá đã có từ Database
          FutureBuilder<List<dynamic>>(
            future: ApiService.getReviewsByProductId(productId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
                  ),
                );
              }

              final reviews = snapshot.data ?? [];

              if (reviews.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'Chưa có đánh giá nào cho sản phẩm này.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 16, color: Color(0xFFEFF6FF)),
                itemBuilder: (context, index) {
                  final rev = reviews[index];
                  final String userName =
                      rev['UserName'] ??
                      rev['USERNAME'] ??
                      rev['User']?['FullName'] ??
                      'Người dùng';
                  final int stars =
                      (rev['RATING'] ?? rev['Rating'] ?? 5) as int;
                  final String comment = rev['COMMENT'] ?? rev['Comment'] ?? '';
                  final String? avatarUrl =
                      rev['Avatar'] ??
                      rev['AVATAR'] ??
                      rev['AvatarUrl'] ??
                      rev['User']?['Avatar'];

                  return _buildReviewItem(userName, stars, comment, avatarUrl);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String extractBrand(String productName) {
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

  // Widget từng mục Bình luận màu Xanh - Trắng
  Widget _buildReviewItem(
    String name,
    int stars,
    String comment,
    String? avatarUrl,
  ) {
    // Xử lý tạo URL hoàn chỉnh cho Avatar nếu là đường dẫn tương đối
    String? finalAvatarUrl = avatarUrl;
    if (finalAvatarUrl != null && finalAvatarUrl.isNotEmpty) {
      if (!finalAvatarUrl.startsWith('http')) {
        finalAvatarUrl =
            '${ApiService.baseUrl.replaceAll('/api', '')}/$finalAvatarUrl';
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFDBEAFE),
                backgroundImage:
                    (finalAvatarUrl != null && finalAvatarUrl.isNotEmpty)
                    ? NetworkImage(finalAvatarUrl)
                    : null,
                child: (finalAvatarUrl == null || finalAvatarUrl.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Color(0xFF1E40AF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  stars,
                  (index) =>
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 36.0),
            child: Text(
              comment,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
