import 'package:flutter/material.dart';

class AlbumSummaryCard extends StatelessWidget {
  final int totalAlbums;
  final int totalPhotos;

  const AlbumSummaryCard({
    super.key,
    required this.totalAlbums,
    required this.totalPhotos,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              " ●  Bộ sưu tập ảnh",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              "Tổng hợp những khoảnh khắc đẹp nhất từ các chuyến du lịch, được chia thành nhiều album theo chủ đề.",
              style: TextStyle(height: 1.5, color: Colors.black87),
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.photo_library_outlined, "$totalAlbums Albums"),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.camera_alt_outlined, "$totalPhotos Photos"),
          ],
        ),
      ),
    );
  }

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
