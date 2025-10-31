import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nhom_3_damh_lttbdd/model/banner.dart'; // Đảm bảo đường dẫn đúng

class BannerDetailScreen extends StatelessWidget {
  final BannerModel banner;
  const BannerDetailScreen({Key? key, required this.banner}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(banner.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh Banner
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                banner.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Text(
                      'Không tải được ảnh',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề
            Text(
              banner.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Ngày hết hạn
            Row(
              children: [
                const Icon(
                  Icons.timer_off_outlined,
                  size: 18,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hết hạn vào: ${DateFormat('dd/MM/yyyy HH:mm').format(banner.endDate)}',
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nội dung chi tiết
            Text(
              banner.content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
