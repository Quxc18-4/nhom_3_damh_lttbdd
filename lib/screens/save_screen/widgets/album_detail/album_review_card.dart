import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/model/album_models.dart';

/// Widget hiển thị thẻ (card) bài viết trong album.
/// Dùng trong danh sách bài viết của album (AlbumDetailScreen chẳng hạn).
class AlbumReviewCard extends StatelessWidget {
  /// Dữ liệu của bài viết (được lấy từ Firestore qua model SavedReviewItem)
  final SavedReviewItem item;

  /// Hàm callback khi người dùng nhấn vào card (để xem chi tiết bài viết)
  final VoidCallback onTap;

  const AlbumReviewCard({Key? key, required this.item, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Bắt sự kiện chạm vào card
      onTap: onTap,

      // Bo góc cho hiệu ứng ripple khi nhấn
      borderRadius: BorderRadius.circular(12),

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),

          // Đổ bóng nhẹ cho card để nổi bật hơn
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        // Chia card thành 2 phần: ảnh và nội dung
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(), // phần ảnh
            _buildContent(), // phần chữ
          ],
        ),
      ),
    );
  }

  /// Phần hiển thị ảnh đại diện của bài viết
  Widget _buildImage() {
    return Expanded(
      flex: 3, // chiếm 3 phần trong tổng 5 phần chiều cao
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Image.network(
          item.imageUrl, // link ảnh từ Firestore
          width: double.infinity,
          fit: BoxFit.cover,

          // Nếu ảnh lỗi, hiển thị biểu tượng thay thế
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.broken_image, size: 40)),
          ),
        ),
      ),
    );
  }

  /// Phần hiển thị tiêu đề và nội dung ngắn gọn của bài viết
  Widget _buildContent() {
    return Expanded(
      flex: 2, // chiếm 2 phần trong tổng 5 phần chiều cao
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề bài viết
            Text(
              item.title,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2, // Giới hạn tối đa 2 dòng
              overflow: TextOverflow.ellipsis, // Cắt bớt nếu quá dài
            ),

            const Spacer(),

            // Hiển thị nội dung mô tả ngắn (nếu có)
            if (item.content.isNotEmpty)
              Text(
                item.content,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
