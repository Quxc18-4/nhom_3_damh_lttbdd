import 'package:flutter/material.dart';

// Đặt widget này vào file album_tab_content.dart hoặc file tương ứng
class AlbumTabContent extends StatelessWidget {
  const AlbumTabContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần giới thiệu ngắn hoặc thống kê album (tương đương _buildIntroductionCard)
          _buildAlbumSummaryCard(),
          const SizedBox(height: 24),
          // Phần nội dung chính: Lưới ảnh (tương đương _buildAchievementsSection)
          _buildPhotoGridSection(),
        ],
      ),
    );
  }

  // --- WIDGETS CON CHO TAB ALBUM ---

  // Phần tóm tắt Album (tương đương Card giới thiệu)
  Widget _buildAlbumSummaryCard() {
    return Card(
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
              style: TextStyle(height: 1.5),
            ),
            const Divider(height: 24),
            // Thống kê Album
            _buildInfoRow(Icons.photo_library_outlined, "12 Albums"),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.camera_alt_outlined, "500+ Photos"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.grey[800])),
      ],
    );
  }

  // Phần lưới ảnh chính (tương đương GridView Thành tích)
  Widget _buildPhotoGridSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            " ↳  Ảnh đã đăng",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // Sử dụng GridView để tạo lưới ảnh (3 cột)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 cột như bố cục mạng xã hội
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1, // Tỷ lệ vuông cho mỗi ô
          ),
          itemCount: 20, // Số lượng ảnh mẫu
          itemBuilder: (context, index) {
            return _buildPhotoItem(index);
          },
        ),
      ],
    );
  }

  Widget _buildPhotoItem(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300], // Màu nền ảnh Placeholder
        borderRadius: BorderRadius.circular(4),
        // Nếu có ảnh thực, thay thế bằng Image.network/Image.asset
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey[500],
        size: 30,
      ),
    );
  }
}