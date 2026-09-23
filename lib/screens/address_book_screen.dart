import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/user_provider.dart';

class AddressBookScreen extends StatelessWidget {
  const AddressBookScreen({super.key});

  // Hàm mở Google Maps theo chuỗi địa chỉ
  Future<void> _openMap(BuildContext context, String address) async {
    if (address.isEmpty || address == 'Chưa cập nhật địa chỉ') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có địa chỉ hợp lệ để tìm kiếm')),
      );
      return;
    }

    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Không thể mở bản đồ')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user ?? {};
    final String address =
        user['Address'] ?? user['address'] ?? 'Chưa cập nhật địa chỉ';
    //final String phone = user['Phone'] ?? user['phone'] ?? 'Chưa cập nhật SĐT';
    final String fullName =
        user['FullName'] ?? user['fullName'] ?? 'Địa chỉ mặc định';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Sổ địa chỉ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: 
            SizedBox(
              height: 100,
              child: Center(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  onTap: () =>
                      _openMap(context, address), // Bấm vào thẻ để mở Google Maps
                  leading: const Icon(
                    Icons.location_on,
                    color: Color(0xFF1E40AF),
                    size: 28,
                  ),
                  title: Text(
                    fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '$address\n',
                      style: const TextStyle(height: 1.4, fontSize: 14),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.open_in_new,
                    color: Colors.grey,
                    size: 20,
                  ), // Icon báo hiệu mở liên kết
                  isThreeLine: true,
                )
              ),
            ),
          ),
        ],
      ),
    );
  }
}
