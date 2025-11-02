import 'package:flutter/material.dart';
import 'photo_viewer.dart';

/// Widget hiển thị lưới ảnh của user
class PhotoGridSection extends StatelessWidget {
  final List<String> photos; // Danh sách URL ảnh

  const PhotoGridSection({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    // Nếu không có ảnh nào, hiển thị placeholder
    if (photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có ảnh nào',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Nếu có ảnh, hiển thị lưới 3 cột
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            " ↳  Ảnh đã đăng",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true, // Cho phép GridView nằm trong Column
          physics:
              const NeverScrollableScrollPhysics(), // Vô hiệu scroll riêng, dùng scroll của parent
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 ảnh / hàng
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) => _buildPhotoItem(context, index),
        ),
      ],
    );
  }

  /// Widget cho từng ô ảnh
  Widget _buildPhotoItem(BuildContext context, int index) {
    final imageUrl = photos[index];
    return GestureDetector(
      onTap: () =>
          _showPhotoViewer(context, index), // Nhấn để xem ảnh toàn màn hình
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4), // Bo góc ảnh
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          // Hiển thị icon nếu ảnh không load được
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  /// Hiển thị PhotoViewer toàn màn hình
  void _showPhotoViewer(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87, // Background mờ tối
      builder: (_) => PhotoViewer(photos: photos, initialIndex: initialIndex),
    );
  }
}
