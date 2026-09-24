import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'product_detail_screen.dart';
import '../services/api_service.dart';
import '../providers/favorite_provider.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List products = [];
  List filteredProducts = [];
  List<String> bannerImages = [];
  List techNewsList = [];
  bool isLoading = true;

  // --- CẤU HÌNH PHÂN TRANG ---
  int _currentPageIndex = 1;
  static const int _itemsPerPage = 10;

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  static const int _virtualInitialPage = 10000;
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _bannerTimer;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _virtualInitialPage);
    _loadData();
    _startAutoSlider();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _bannerTimer?.cancel();
    _refreshTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _fetchPromotions(),
      _fetchProducts(),
      _fetchTechNews(),
    ]);
  }

  Future<void> _fetchPromotions() async {
    try {
      final res = await ApiService.getPromotions();
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          bannerImages = data
              .map<String>((item) => (item['IMAGEURL'] ?? item['ImageUrl'] ?? item['imageUrl'] ?? '').toString())
              .where((url) => url.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching promotions: $e');
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final res = await ApiService.getProducts();
      if (res.statusCode == 200) {
        if (mounted) {
          final data = jsonDecode(res.body);
          setState(() {
            products = data;
            filteredProducts = data;
            _currentPageIndex = 1; // Reset về trang 1 khi tải lại
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching products: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Hàm tải tin tức từ Web API
  Future<void> _fetchTechNews() async {
    try {
      final res = await ApiService.getTechNews();
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          techNewsList = data; // Số lượng bài viết tự động cập nhật theo Web API
        });
      }
    } catch (e) {
      print('Error fetching tech news: $e');
    }
  }

  Widget _buildTechNewsSection() {
    // 1. Dữ liệu tin tức mẫu dùng Asset local kèm tiêu đề chuẩn
    final List<Map<String, String>> defaultNewsList = [
      {
        'imageUrl': 'lib/images/tincongnghe01.jpg',
        'title': 'Thay mainboard có cần cài lại Win không? Cần làm gì khi thay mainboard?',
      },
      {
        'imageUrl': 'lib/images/tincongnghe02.jpg',
        'title': 'Tổng hợp thông tin mới nhất về Grand Theft Auto 6',
      },
      {
        'imageUrl': 'lib/images/tincongnghe03.jpg',
        'title': 'Tai Ương Final Chapter: Phân tích cốt truyện, kết thúc game',
      },
    ];

    // 2. Sử dụng dữ liệu API nếu có, ngược lại dùng danh sách mẫu
    final displayList = techNewsList.isNotEmpty ? techNewsList : defaultNewsList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề section
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 12.0),
          child: Text(
            'TIN CÔNG NGHỆ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Danh sách cuộn ngang
        SizedBox(
          height: 190, // Tăng chiều cao để chứa cả ảnh và dòng tiêu đề bên dưới
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final item = displayList[index];

              final String imageUrl =
                  (item['IMAGEURL'] ?? item['ImageUrl'] ?? item['imageUrl'] ?? '').toString();
              final String title =
                  (item['TITLE'] ?? item['Title'] ?? item['title'] ?? '').toString();

              return Container(
                width: 230,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      // Xử lý khi nhấn vào tin tức
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // phần Hình ảnh (Phía trên)
                        SizedBox(
                          height: 125,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: imageUrl.startsWith('http')
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                          ),
                        ),

                        // Phần Tiêu đề chữ (Phía dưới)
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _startAutoSlider() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && bannerImages.isNotEmpty) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _nextBanner() {
    if (_pageController.hasClients && bannerImages.isNotEmpty) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousBanner() {
    if (_pageController.hasClients && bannerImages.isNotEmpty) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _performSearch(String query) {
    final keyword = query.toLowerCase().trim();
    setState(() {
      _currentPageIndex = 1; // Reset về trang 1 khi tìm kiếm
      if (keyword.isEmpty) {
        filteredProducts = products;
      } else {
        filteredProducts = products.where((item) {
          final productName = (item['ProductName'] ?? item['PRODUCTNAME'] ?? '').toString().toLowerCase();
          final brand = (item['Brand'] ?? item['BRAND'] ?? '').toString().toLowerCase();
          final categoryName = (item['CategoryName'] ?? item['CATEGORYNAME'] ?? '').toString().toLowerCase();

          return productName.contains(keyword) || brand.contains(keyword) || categoryName.contains(keyword);
        }).toList();
      }
    });
  }

  String formatCurrency(num amount) {
    String str = amount.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
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

  @override
  Widget build(BuildContext context) {
    // --- LÝ THUYẾT VÀ TÍNH TOÁN PHÂN TRANG ---
    final int totalItems = filteredProducts.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();

    final int startIndex = (_currentPageIndex - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage > totalItems) 
        ? totalItems 
        : startIndex + _itemsPerPage;

    // Danh sách 10 sản phẩm hiển thị trên trang hiện tại
    final List currentPageProducts = (startIndex < totalItems)
        ? filteredProducts.sublist(startIndex, endIndex)
        : [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        title: Image.asset(
          'lib/images/thuonghieu.png',
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'MANB.VN',
              style: TextStyle(color: Colors.white, fontSize: 16),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: HoverScaleIcon(
              onTap: () async {
                final Uri zaloUri = Uri.parse('https://zalo.me/0909680426');
                if (await canLaunchUrl(zaloUri)) {
                  await launchUrl(zaloUri, mode: LaunchMode.externalApplication);
                }
              },
              child: ClipOval(
                child: Image.asset(
                  'lib/images/zalo.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: SizedBox(
              height: 40,
              child: RawAutocomplete<Map<String, dynamic>>(
                textEditingController: _searchController,
                focusNode: _searchFocusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.trim().isEmpty) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }
                  return products.where((item) {
                    final name = (item['ProductName'] ?? item['PRODUCTNAME'] ?? '').toString().toLowerCase();
                    return name.contains(textEditingValue.text.toLowerCase().trim());
                  }).cast<Map<String, dynamic>>();
                },
                displayStringForOption: (option) => option['ProductName'] ?? option['PRODUCTNAME'] ?? '',
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) {
                      _performSearch(value);
                    },
                    onSubmitted: (value) {
                      _performSearch(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm sản phẩm...',
                      hintStyle: const TextStyle(fontSize: 16, color: Colors.black54),
                      fillColor: Colors.white,
                      filled: true,
                      prefixIcon: const Icon(Icons.search, color: Colors.black87, size: 28),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.black87, size: 24),
                              onPressed: () {
                                controller.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 6.0,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 20,
                        constraints: const BoxConstraints(maxHeight: 280),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: Color(0xFFEEEEEE),
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            final item = options.elementAt(index);
                            final imageUrl = item['ImageUrl'] ?? item['IMAGEURL'] ?? item['ImageURL'] ?? '';
                            final productName = item['ProductName'] ?? item['PRODUCTNAME'] ?? '';
                            final double price = (item['Price'] ?? item['PRICE'] ?? 0).toDouble();
                            final double discountPrice = (item['DiscountPrice'] ?? item['DISCOUNTPRICE'] ?? price).toDouble();

                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 36,
                                height: 36,
                                padding: const EdgeInsets.all(2),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, fit: BoxFit.contain)
                                    : const Icon(Icons.computer, size: 20, color: Colors.grey),
                              ),
                              title: Text(
                                productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
                              ),
                              subtitle: Text(
                                '${formatCurrency(discountPrice)} đ',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                              ),
                              onTap: () {
                                onSelected(item);
                                FocusScope.of(context).unfocus();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(product: item),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Auto Slider
                    if (bannerImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 130,
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index % bannerImages.length;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final imageIndex = index % bannerImages.length;
                                  return Image.network(
                                    bannerImages[imageIndex],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, _, _) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    bannerImages.length,
                                    (index) => AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentPage == index
                                            ? Colors.white
                                            : Colors.grey.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ), 

                    _buildTechNewsSection(), 

                    // Title
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'SẢN PHẨM NỔI BẬT'
                            : '🔍 KẾT QUẢ TÌM KIẾM (${filteredProducts.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    // Products Grid
                    filteredProducts.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'Không tìm thấy sản phẩm nào.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.50,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: currentPageProducts.length,
                            itemBuilder: (context, index) {
                              final item = currentPageProducts[index];
                              final imageUrl =
                                  item['ImageUrl'] ??
                                  item['IMAGEURL'] ??
                                  item['ImageURL'] ??
                                  '';
                              final productName =
                                  item['ProductName'] ??
                                  item['PRODUCTNAME'] ??
                                  'Chưa có tên';
                              final double originalPrice =
                                  (item['Price'] ?? item['PRICE'] ?? 0)
                                      .toDouble();
                              final double discountPrice =
                                  (item['DiscountPrice'] ?? item['DISCOUNTPRICE'] ?? originalPrice * 0.82)
                                      .toDouble();

                              final double discountAmount =
                                  originalPrice > discountPrice ? originalPrice - discountPrice : 0;
                              final int discountPercent = originalPrice > 0
                                  ? ((discountAmount / originalPrice) * 100).round()
                                  : 0;

                              final String brandName = extractBrand(
                                productName,
                              );

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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      Color(0xFF8B5CF6),
                                                      Color(0xFF1E40AF),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'TIẾT KIỆM',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text.rich(
                                                      TextSpan(
                                                        children: [
                                                          TextSpan(
                                                            text:
                                                                '${formatCurrency(discountAmount)} ',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          const TextSpan(
                                                            text: 'đ',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
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
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
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
                                                Consumer2<FavoriteProvider, UserProvider>(
                                                  builder: (context, favProvider, userProvider, child) {
                                                    final userId = userProvider.currentUserId; 
                                                    final isFav = favProvider.isFavorite(item);

                                                    return IconButton(
                                                      icon: Icon(
                                                        isFav ? Icons.favorite : Icons.favorite_border,
                                                        color: isFav ? Color(0xFF1E40AF) : const Color(0xFF1E40AF),
                                                      ),
                                                      onPressed: () {
                                                        if (userId == null) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('Vui lòng đăng nhập để yêu thích sản phẩm!')),
                                                          );
                                                          return;
                                                        }

                                                        favProvider.toggleFavorite(item, userId); 
                                                      },
                                                    );
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
                                            buildPriceText(
                                              discountPrice,
                                              color: const Color(0xFF1E40AF),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            const SizedBox(height: 2),
                                            if (originalPrice > discountPrice)
                                              Row(
                                                children: [
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              '${formatCurrency(originalPrice)} ',
                                                          style: const TextStyle(
                                                            color: Color(
                                                              0xFF9E9E9E,
                                                            ),
                                                            fontSize: 12,
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text: 'đ',
                                                          style: TextStyle(
                                                            color: const Color(
                                                              0xFF9E9E9E,
                                                            ),
                                                            fontSize: 12,
                                                            decoration:
                                                                TextDecoration.combine(<
                                                                  TextDecoration
                                                                >[
                                                                  TextDecoration
                                                                      .lineThrough,
                                                                  TextDecoration
                                                                      .underline,
                                                                ]),
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
                          ),

                    // --- THANH PHÂN TRANG (PAGINATION BAR) ---
                    if (totalPages > 1) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Nút Previous
                          IconButton(
                            onPressed: _currentPageIndex > 1
                                ? () {
                                    setState(() {
                                      _currentPageIndex--;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            color: const Color(0xFF1E40AF),
                            disabledColor: Colors.grey[300],
                          ),
                          
                          // Các nút chọn số trang
                          ...List.generate(totalPages, (index) {
                            final pageNumber = index + 1;
                            final isSelected = pageNumber == _currentPageIndex;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _currentPageIndex = pageNumber;
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF1E40AF) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF1E40AF) : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    '$pageNumber',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF1E40AF),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Nút Next
                          IconButton(
                            onPressed: _currentPageIndex < totalPages
                                ? () {
                                    setState(() {
                                      _currentPageIndex++;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            color: const Color(0xFF1E40AF),
                            disabledColor: Colors.grey[300],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0.0, right: 0.0),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF1E40AF),
          heroTag: null,
          onPressed: () => _makePhoneCall('0909680426'),
          child: const Icon(Icons.call, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể thực hiện cuộc gọi đến $phoneNumber')),
        );
      }
    }
  }

  Widget buildPriceText(
    num price, {
    Color color = const Color(0xFF1E40AF),
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${formatCurrency(price)} ',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
          TextSpan(
            text: 'đ',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

class HoverScaleIcon extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const HoverScaleIcon({super.key, required this.child, required this.onTap});

  @override
  State<HoverScaleIcon> createState() => _HoverScaleIconState();
}

class _HoverScaleIconState extends State<HoverScaleIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.25 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}