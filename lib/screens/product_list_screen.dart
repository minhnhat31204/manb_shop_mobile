import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'product_detail_screen.dart';

import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import '../providers/favorite_provider.dart';
import '../providers/user_provider.dart';

class ProductListScreen extends StatefulWidget {
  final String categoryTitle; // Ví dụ: "HP", "DELL", "Laptop HP",...
  final VoidCallback? onGoToHome;

  const ProductListScreen({
    super.key,
    this.categoryTitle = 'HP',
    this.onGoToHome,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;

  // Trạng thái bộ lọc thương hiệu hiện tại (null = hiển thị tất cả Laptop)
  String? _currentSelectedBrand;

  // Search State
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Filter & Sort States
  String _selectedSort = 'Sản phẩm mới nhất';
  RangeValues _priceRange = const RangeValues(0, 500000000);
  String? _selectedSeries;
  String? _selectedDemand;
  String? _selectedCpu;

  @override
  void initState() {
    super.initState();
    _currentSelectedBrand = _getTargetBrand();
    _fetchProducts();
  }

  // 🟢 THÊM ĐOẠN NÀY ĐỂ BẮT SỰ THAY ĐỔI KHI ĐỔI TÊN THƯƠNG HIỆU
  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryTitle != widget.categoryTitle) {
      setState(() {
        _currentSelectedBrand = _getTargetBrand(); // Cập nhật lại brand mới (VD: MSI)
        _applyFilters(); // Lọc lại danh sách sản phẩm
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Tách tên Hãng: chuỗi chữ cái in hoa liền nhau, không chứa số (VD: HP, DELL, ASUS, ACER)
  String _extractBrand(String productName) {
    if (productName.trim().isEmpty) return '';
    List<String> words = productName.trim().split(RegExp(r'\s+'));
    for (String word in words) {
      String clean = word.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');
      if (clean.isNotEmpty && RegExp(r'^[A-Z]+$').hasMatch(clean)) {
        return clean;
      }
    }
    return words[0].toUpperCase();
  }

  // Tách tên hãng mong muốn từ categoryTitle truyền vào
  String _getTargetBrand() {
    String title = widget.categoryTitle;
    List<String> words = title.split(RegExp(r'\s+'));
    for (String w in words) {
      String clean = w.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');
      if (clean.isNotEmpty && RegExp(r'^[A-Z]+$').hasMatch(clean)) {
        return clean.toUpperCase();
      }
    }
    String brand = title.replaceAll('Laptop', '').trim().toUpperCase();
    return brand.isEmpty ? 'HP' : brand;
  }

  Future<void> _fetchProducts() async {
    try {
      final res = await ApiService.getProducts();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _allProducts = List<Map<String, dynamic>>.from(
              data.map((x) => Map<String, dynamic>.from(x))
            );
            _applyFilters();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<dynamic> list = List.from(_allProducts);

    // 1. Lọc theo Thương hiệu
    if (_currentSelectedBrand != null && _currentSelectedBrand!.isNotEmpty) {
      String target = _currentSelectedBrand!.toUpperCase();
      list = list.where((item) {
        final name = (item['ProductName'] ?? item['PRODUCTNAME'] ?? '').toString();
        final brandFromDb = (item['Brand'] ?? item['BRAND'] ?? '').toString().toUpperCase();
        final extracted = _extractBrand(name);

        // 🟢 CHỈ GIỮ SẢN PHẨM CÓ BRAND TƯƠNG ỨNG
        if (brandFromDb.isNotEmpty) {
          return brandFromDb == target;
        }
        return extracted == target;
      }).toList();
    }

    // 2. Lọc theo Tìm kiếm
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((item) {
        final name = (item['ProductName'] ?? item['PRODUCTNAME'] ?? '')
            .toString()
            .toLowerCase();
        return name.contains(query);
      }).toList();
    }

    // 3. Lọc theo Khoảng giá
    list = list.where((item) {
      final double price =
          (item['DiscountPrice'] ??
                  item['DISCOUNTPRICE'] ??
                  item['Price'] ??
                  item['PRICE'] ??
                  0)
              .toDouble();
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    // 4. Lọc Series / CPU
    if (_selectedSeries != null) {
      list = list.where((item) {
        final name = (item['ProductName'] ?? item['PRODUCTNAME'] ?? '')
            .toString()
            .toLowerCase();
        return name.contains(_selectedSeries!.toLowerCase());
      }).toList();
    }

    if (_selectedCpu != null) {
      list = list.where((item) {
        final name = (item['ProductName'] ?? item['PRODUCTNAME'] ?? '')
            .toString()
            .toLowerCase();
        return name.contains(_selectedCpu!.toLowerCase());
      }).toList();
    }

    // 5. Sắp xếp
    if (_selectedSort == 'Giá thấp đến cao') {
      list.sort((a, b) {
        double p1 =
            (a['DiscountPrice'] ?? a['DISCOUNTPRICE'] ?? a['Price'] ?? 0)
                .toDouble();
        double p2 =
            (b['DiscountPrice'] ?? b['DISCOUNTPRICE'] ?? b['Price'] ?? 0)
                .toDouble();
        return p1.compareTo(p2);
      });
    } else if (_selectedSort == 'Giá cao đến thấp') {
      list.sort((a, b) {
        double p1 =
            (a['DiscountPrice'] ?? a['DISCOUNTPRICE'] ?? a['Price'] ?? 0)
                .toDouble();
        double p2 =
            (b['DiscountPrice'] ?? b['DISCOUNTPRICE'] ?? b['Price'] ?? 0)
                .toDouble();
        return p2.compareTo(p1);
      });
    }

    // GÁN TRỰC TIẾP, KHÔNG DÙNG setState THÊM Ở ĐÂY
    _filteredProducts = list;
  }

  String _formatCurrency(num amount) {
    String str = amount.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bộ lọc tìm kiếm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Khoảng giá (đ)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_formatCurrency(_priceRange.start)}đ'),
                              Text('${_formatCurrency(_priceRange.end)}đ'),
                            ],
                          ),
                          RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 500000000,
                            divisions: 100,
                            activeColor: const Color(0xFF1D4ED8),
                            onChanged: (values) {
                              setModalState(() => _priceRange = values);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Series model',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                [
                                      '14',
                                      '15',
                                      'Victus',
                                      'Pavilion',
                                      'ProBook',
                                      'EliteBook',
                                      'ROG',
                                      'TUF',
                                      'ThinkPad',
                                    ]
                                    .map(
                                      (series) => _buildFilterChip(
                                        label: series,
                                        isSelected: _selectedSeries == series,
                                        onTap: () {
                                          setModalState(() {
                                            _selectedSeries =
                                                _selectedSeries == series
                                                ? null
                                                : series;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Series CPU',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                [
                                      'Core i3',
                                      'Core i5',
                                      'Core i7',
                                      'Core Ultra 5',
                                      'Core Ultra 7',
                                      'Ryzen 5',
                                      'Ryzen 7',
                                    ]
                                    .map(
                                      (cpu) => _buildFilterChip(
                                        label: cpu,
                                        isSelected: _selectedCpu == cpu,
                                        onTap: () {
                                          setModalState(() {
                                            _selectedCpu = _selectedCpu == cpu
                                                ? null
                                                : cpu;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _priceRange = const RangeValues(0, 500000000);
                              _selectedSeries = null;
                              _selectedDemand = null;
                              _selectedCpu = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1D4ED8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Xóa bộ lọc',
                            style: TextStyle(color: Color(0xFF1D4ED8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _applyFilters();
                            });
                          },
                          child: const Text(
                            'Áp dụng',
                            style: TextStyle(color: Colors.white),
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
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) / 2,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1D4ED8)
                : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1D4ED8) : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String initialBrand = _getTargetBrand();
    final String currentTitle = _currentSelectedBrand != null
        ? 'Laptop $_currentSelectedBrand'
        : 'Laptop';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 18,
          ),
          onPressed: widget.onGoToHome ?? () => Navigator.pop(context),
        ),
        title: SizedBox(
          height: 38,
          child: RawAutocomplete<Map<String, dynamic>>(
            textEditingController: _searchController,
            focusNode: _searchFocusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.trim().isEmpty) {
                return const Iterable<Map<String, dynamic>>.empty();
              }
              return _allProducts.where((item) {
                final name = (item['ProductName'] ?? item['PRODUCTNAME'] ?? '')
                    .toString()
                    .toLowerCase();
                return name.contains(
                  textEditingValue.text.toLowerCase().trim(),
                );
              }).cast<Map<String, dynamic>>();
            },
            displayStringForOption: (option) =>
                option['ProductName'] ?? option['PRODUCTNAME'] ?? '',
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Bạn muốn mua gì hôm nay...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      fillColor: const Color(0xFFF3F4F6),
                      filled: true,
                      prefixIcon: IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Color(0xFF1D4ED8),
                          size: 20,
                        ),
                        onPressed: () {
                          _applyFilters();
                          FocusScope.of(context).unfocus();
                        },
                      ),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 18,
                              ),
                              onPressed: () {
                                controller.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                    ),
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6.0,
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 80,
                    constraints: const BoxConstraints(maxHeight: 320),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      itemBuilder: (BuildContext context, int index) {
                        final item = options.elementAt(index);
                        final imageUrl =
                            item['ImageUrl'] ??
                            item['IMAGEURL'] ??
                            item['ImageURL'] ??
                            '';
                        final productName =
                            item['ProductName'] ?? item['PRODUCTNAME'] ?? '';
                        final double price =
                            (item['Price'] ?? item['PRICE'] ?? 0).toDouble();
                        final double discountPrice =
                            (item['DiscountPrice'] ??
                                    item['DISCOUNTPRICE'] ??
                                    price)
                                .toDouble();
                        final double discountAmount = price > discountPrice
                            ? price - discountPrice
                            : 0;
                        final int discountPercent = price > 0
                            ? ((discountAmount / price) * 100).round()
                            : 0;

                        return ListTile(
                          dense: true,
                          leading: SizedBox(
                            width: 40,
                            height: 40,
                            child: imageUrl.isNotEmpty
                                ? Image.network(imageUrl, fit: BoxFit.contain)
                                : const Icon(
                                    Icons.computer,
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                          ),
                          title: Text(
                            productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_formatCurrency(discountPrice)} đ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                              if (price > discountPrice)
                                Row(
                                  children: [
                                    Text(
                                      '${_formatCurrency(price)} đ',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '-$discountPercent%',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          onTap: () {
                            onSelected(item);
                            FocusScope.of(context).unfocus();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  product: Map<String, dynamic>.from(item),
                                ),
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
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              final count = cart.totalItemsCount;
              return IconButton(
                icon: Badge(
                  label: Text('$count'),
                  isLabelVisible: count > 0,
                  backgroundColor: const Color(0xFFDC2626),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black87,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. BREADCRUMB TƯƠNG TÁC
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: const Color(
                      0xFFF4F5F7,
                    ), // Đổi màu nền xám đồng bộ với màu ứng dụng
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // 1.1 Trang chủ
                          GestureDetector(
                            onTap:
                                widget.onGoToHome ??
                                () => Navigator.pop(context),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.home_outlined,
                                  size: 16,
                                  color: Color(0xFF1D4ED8),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Trang chủ',
                                  style: TextStyle(
                                    color: Color(0xFF1D4ED8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            ' > ',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),

                          // 1.2 Laptop
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentSelectedBrand = null;
                                _applyFilters();
                              });
                            },
                            child: Text(
                              'Laptop',
                              style: TextStyle(
                                color: const Color(0xFF1D4ED8),
                                fontSize: 12,
                                fontWeight: _currentSelectedBrand == null
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),

                          // 1.3 Laptop Brand
                          if (initialBrand.isNotEmpty) ...[
                            const Text(
                              ' > ',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentSelectedBrand = initialBrand;
                                  _applyFilters();
                                });
                              },
                              child: Text(
                                'Laptop $initialBrand',
                                style: TextStyle(
                                  color: const Color(0xFF1D4ED8),
                                  fontSize: 12,
                                  fontWeight:
                                      _currentSelectedBrand == initialBrand
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 2. Title + Đếm Số Lượng Sản Phẩm
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Text(
                          currentTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${_filteredProducts.length} sản phẩm)',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Banner Khuyến Mãi Ngang
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF1D4ED8),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Text(
                      '$currentTitle Tặng Ưu Đãi Đặc Biệt',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // 4. Thanh Sắp xếp & Bộ lọc
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: _selectedSort,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          items:
                              [
                                'Sản phẩm mới nhất',
                                'Giá thấp đến cao',
                                'Giá cao đến thấp',
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedSort = newValue;
                                _applyFilters();
                              });
                            }
                          },
                        ),
                        InkWell(
                          onTap: _showFilterModal,
                          child: Row(
                            children: const [
                              Text(
                                'Bộ lọc',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.filter_alt_outlined,
                                size: 18,
                                color: Color(0xFF1D4ED8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 5. Grid Sản Phẩm
                  _filteredProducts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              'Không tìm thấy sản phẩm nào.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.50,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final item = _filteredProducts[index];
                            return _buildProductCard(item);
                          },
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0.0, right: 0.0), // 👈 Tăng số này (ví dụ 20, 30, 40) để đẩy nút THẤP XUỐNG
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF1D4ED8),
          heroTag: null,
          onPressed: () => _makePhoneCall('0909680426'),
          child: const Icon(Icons.call, color: Colors.white),
        ),
      ),
    );
  }

  double _toDouble(dynamic val, double fallback) {
    if (val == null) return fallback;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? fallback;
    return fallback;
  }

  // Mở ứng dụng gọi điện tới số 0909680426
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể thực hiện cuộc gọi đến $phoneNumber')),
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi mở ứng dụng gọi điện: $e');
    }
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final String imageUrl =
        item['ImageUrl'] ?? item['IMAGEURL'] ?? item['ImageURL'] ?? '';
    final String productName =
        item['ProductName'] ?? item['PRODUCTNAME'] ?? 'Chưa có tên';
    final double originalPrice = _toDouble(item['Price'] ?? item['PRICE'], 0.0);

    final double discountPrice = _toDouble(
      item['DiscountPrice'] ?? item['DISCOUNTPRICE'],
      originalPrice * 0.82,
    );

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
            builder: (context) => ProductDetailScreen(
              product: Map<String, dynamic>.from(item),
            ),
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
            // Khung Ảnh + Badge Tiết kiệm
            Stack(
              children: [
                Container(
                  height: 180, // ✅ Đổi từ 160 -> 180 cho khớp kích thước
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

            // Phân vùng nội dung
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
                      Consumer2<FavoriteProvider, UserProvider>(
                        builder: (context, favProvider, userProvider, child) {
                          final userId = userProvider.currentUserId; 
                          final isFav = favProvider.isFavorite(item);

                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : const Color(0xFF1D4ED8),
                              size: 20,
                            ),
                            onPressed: () {
                              if (userId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vui lòng đăng nhập để yêu thích sản phẩm!'),
                                  ),
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

                  // GIÁ GỐC
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
  }
}
