import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/model/saved_models.dart';

/// Widget hiển thị 1 thẻ (card) đại diện cho một mục đã lưu
/// Có thể là bài viết (review) hoặc địa điểm (place)
class SavedItemCard extends StatelessWidget {
  /// Dữ liệu của mục đã lưu
  final SavedItem item;

  /// Khi người dùng chạm vào (xem chi tiết)
  final VoidCallback onTap;

  /// Khi người dùng nhấn giữ hoặc mở menu
  final VoidCallback onLongPress;

  const SavedItemCard({
    Key? key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem item thuộc loại Review hay không
    bool isReview = item.category == SavedCategory.review;

    return InkWell(
      // Xử lý khi người dùng nhấn và giữ hoặc chạm
      onTap: onTap,
      onLongPress: onLongPress,

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        // Bố cục ngang: ảnh bên trái, nội dung bên phải
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemImage(isReview),
            const SizedBox(width: 12),
            Expanded(child: _buildItemInfo(isReview)),
          ],
        ),
      ),
    );
  }

  /// Phần ảnh thu nhỏ của mục
  Widget _buildItemImage(bool isReview) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          // Hiển thị ảnh chính
          Image.network(
            item.imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            // Nếu ảnh lỗi -> hiện icon mặc định
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.broken_image)),
            ),
          ),

          // Nhãn nhỏ ở góc ảnh (ví dụ: "Bài viết" / "Địa điểm")
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isReview
                    ? Colors.lightBlue.shade700
                    : Colors.orange.shade600,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                categoryToVietnamese(item.category), // Đổi enum thành chữ
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Phần thông tin chính: tiêu đề, tác giả hoặc đánh giá, địa điểm...
  Widget _buildItemInfo(bool isReview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề + nút menu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            // Nút ba chấm (menu) ở góc phải
            IconButton(
              onPressed: onLongPress,
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Hiển thị tác giả hoặc đánh giá (rating)
        _buildAuthorOrRating(isReview),

        // Nếu là địa điểm thì hiển thị thêm vị trí
        if (item.category == SavedCategory.place) ...[
          const SizedBox(height: 4),
          _buildLocation(),
        ],
      ],
    );
  }

  /// Hiển thị tên tác giả (đối với bài viết) hoặc rating (đối với địa điểm)
  Widget _buildAuthorOrRating(bool isReview) {
    if (isReview) {
      // Trường hợp là bài viết
      return Row(
        children: [
          const Icon(Icons.person_pin, size: 16, color: Colors.black54),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              item.authorOrRating, // Tên tác giả
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      // Trường hợp là địa điểm (hiển thị điểm đánh giá)
      return Text(
        item.authorOrRating,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  /// Hiển thị địa chỉ (chỉ dùng cho địa điểm)
  Widget _buildLocation() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 14, color: Colors.red.shade400),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            item.location,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
