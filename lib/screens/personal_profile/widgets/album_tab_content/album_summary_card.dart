import 'package:flutter/material.dart';

/// Widget hiển thị tổng quan album của user
class AlbumSummaryCard extends StatelessWidget {
  final int totalAlbums; // Tổng số album
  final int totalPhotos; // Tổng số ảnh

  const AlbumSummaryCard({
    super.key,
    required this.totalAlbums,
    required this.totalPhotos,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1, // Độ nổi nhẹ
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Bo góc card
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Padding trong card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề card
            const Text(
              " ●  Bộ sưu tập ảnh",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            // Mô tả nội dung
            const Text(
              "Tổng hợp những khoảnh khắc đẹp nhất từ các chuyến du lịch, được chia thành nhiều album theo chủ đề.",
              style: TextStyle(height: 1.5, color: Colors.black87),
            ),
            const Divider(height: 24), // Ngăn cách thông tin
            // Thông tin số lượng album
            _buildInfoRow(Icons.photo_library_outlined, "$totalAlbums Albums"),
            const SizedBox(height: 8),
            // Thông tin số lượng ảnh
            _buildInfoRow(Icons.camera_alt_outlined, "$totalPhotos Photos"),
          ],
        ),
      ),
    );
  }

  /// Widget hiển thị icon và text theo hàng
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700], size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.black)),
      ],
    );
  }
}
