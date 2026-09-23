import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ShowroomScreen extends StatefulWidget {
  const ShowroomScreen({super.key});

  @override
  State<ShowroomScreen> createState() => _ShowroomScreenState();
}

class _ShowroomScreenState extends State<ShowroomScreen> {
  static const primaryColor = Color(0xFF1E40AF);

  final List<Map<String, String>> showrooms = const [
    {
      'name': 'Showroom TP. Hồ Chí Minh',
      'address': 'Số 1 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
      'phone': '1900 1234',
      'region': 'TP. Hồ Chí Minh',
    },
    {
      'name': 'Showroom Hà Nội',
      'address': 'Số 10 Lý Thái Tổ, Hoàn Kiếm, Hà Nội',
      'phone': '1900 5678',
      'region': 'Hà Nội',
    },
    {
      'name': 'Showroom Đà Nẵng',
      'address': '230 Nguyễn Văn Linh, Thanh Khê, Đà Nẵng',
      'phone': '1900 9012',
      'region': 'Đà Nẵng',
    },
    {
      'name': 'Showroom Cần Thơ',
      'address': 'Số 50 Đường 30 Tháng 4, Ninh Kiều, Cần Thơ',
      'phone': '1900 3456',
      'region': 'Cần Thơ',
    },
  ];

  // Danh sách các khu vực lọc
  final List<String> regions = const [
    'Tất cả khu vực',
    'TP. Hồ Chí Minh',
    'Hà Nội',
    'Đà Nẵng',
    'Cần Thơ',
  ];

  String _selectedRegion = 'Tất cả khu vực';
  List<Map<String, String>> _filteredShowrooms = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredShowrooms = showrooms;
  }

  // Hàm kết hợp lọc theo từ khóa + vùng miền
  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredShowrooms = showrooms.where((item) {
        final matchesQuery = item['name']!.toLowerCase().contains(query) ||
            item['address']!.toLowerCase().contains(query);
        final matchesRegion = _selectedRegion == 'Tất cả khu vực' ||
            item['region'] == _selectedRegion;

        return matchesQuery && matchesRegion;
      }).toList();
    });
  }

  Future<void> _openMap(BuildContext context, String address) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở bản đồ')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Hệ thống Showroom',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Khu vực Lọc & Tìm kiếm
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                // 1. Ô Tìm kiếm
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilter(),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tên, địa chỉ...',
                    hintStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: primaryColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Dropdown danh sách xổ xuống lọc thành phố
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRegion,
                      isExpanded: true,
                      icon: const Icon(Icons.filter_list, color: primaryColor),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedRegion = newValue;
                          });
                          _applyFilter();
                        }
                      },
                      items: regions.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách Showroom
          Expanded(
            child: _filteredShowrooms.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy showroom phù hợp',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredShowrooms.length,
                    itemBuilder: (context, index) {
                      final item = _filteredShowrooms[index];
                      return Card(
                        elevation: 0.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        color: Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          onTap: () => _openMap(context, item['address']!),
                          leading: const ContainerIcon(
                            icon: Icons.store,
                            color: primaryColor,
                          ),
                          title: Text(
                            item['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${item['address']}\nHotline: ${item['phone']}',
                              style: const TextStyle(
                                height: 1.4,
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.directions,
                            color: primaryColor,
                            size: 24,
                          ),
                          isThreeLine: true,
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

class ContainerIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const ContainerIcon({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}