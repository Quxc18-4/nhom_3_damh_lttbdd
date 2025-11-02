// File: screens/admin_only/widget/banner_management_widgets.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';

/// Widget hiển thị danh sách các banner
// `StatelessWidget`
class BannersList extends StatelessWidget {
  // Nhận `stream` và 1 `callback` `onDelete`
  final Stream<QuerySnapshot> stream;
  final Function(String, String) onDelete;

  const BannersList({Key? key, required this.stream, required this.onDelete})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dùng `StreamBuilder` để lắng nghe `stream`
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có banner nào.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final banners = snapshot.data!.docs;
        // Hiển thị `ListView`
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: banners.length,
          itemBuilder: (context, index) {
            final banner = banners[index];
            // Với mỗi `banner`, tạo 1 `BannerCard`
            return BannerCard(
              banner: banner,
              // **Truyền Callback:**
              // Khi `BannerCard` gọi `onDelete`...
              onDelete: () =>
                  // ...hãy gọi `onDelete` của cha, truyền
                  // ID và Title (để hiển thị dialog xác nhận)
                  onDelete(banner.id, (banner.data() as Map)['title'] ?? ''),
            );
          },
        );
      },
    );
  }
}

/// Widget hiển thị thẻ của một banner
// `StatelessWidget`
class BannerCard extends StatelessWidget {
  final DocumentSnapshot banner;
  final VoidCallback onDelete; // Nhận 1 hàm callback

  const BannerCard({Key? key, required this.banner, required this.onDelete})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Trích xuất dữ liệu (an toàn)
    final data = banner.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Không có tiêu đề';
    final content = data['content'] ?? '';
    final imageUrl = data['imageUrl'] ?? 'N/A';
    // Chuyển `Timestamp` (từ Firestore) -> `DateTime` (của Dart)
    final startDate = (data['startDate'] as Timestamp?)?.toDate();
    final endDate = (data['endDate'] as Timestamp?)?.toDate();

    // 2. **Logic nghiệp vụ (cục bộ):**
    // Xử lý logic *hiển thị* (UI Logic) ngay tại đây
    // Dựa trên `startDate` và `endDate` để quyết định
    // màu sắc và text (status).
    Color statusColor = Colors.grey;
    String statusText = 'Unknown';
    if (startDate != null && endDate != null) {
      final now = DateTime.now();
      if (now.isBefore(startDate)) {
        statusColor = Colors.blue;
        statusText = 'Sắp diễn ra';
      } else if (now.isAfter(endDate)) {
        statusColor = Colors.red;
        statusText = 'Hết hạn';
      } else {
        statusColor = Colors.green;
        statusText = 'Đang hiển thị';
      }
    }

    // 3. Giao diện (Build UI)
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  // Cho Tiêu đề chiếm phần lớn
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                // Cái "tag" (chip) hiển thị status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1), // Nền mờ
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor), // Viền
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  content,
                  style: TextStyle(color: Colors.grey[800], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Hiển thị ảnh (nếu có)
            if (imageUrl != 'N/A' && imageUrl.startsWith('http'))
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text(
                          'Không tải được ảnh. URL không hợp lệ.',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'URL Ảnh: $imageUrl',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // `...` (Spread operator): Dùng để chèn
            // nhiều widget (nếu điều kiện `if` đúng)
            if (startDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Bắt đầu: ${DateFormat('dd/MM/yyyy HH:mm').format(startDate)}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
            if (endDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Kết thúc: ${DateFormat('dd/MM/yyyy HH:mm').format(endDate)}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Xóa Banner'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: onDelete, // Gọi callback `onDelete`
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
