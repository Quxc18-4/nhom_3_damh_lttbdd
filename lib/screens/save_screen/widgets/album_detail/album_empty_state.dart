import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget hiển thị trạng thái "chưa có bài viết nào"
/// Dùng trong màn hình Album hoặc Bookmark khi danh sách trống.
class AlbumEmptyState extends StatelessWidget {
  const AlbumEmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      // Dùng Center để căn giữa toàn bộ nội dung
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Căn giữa theo chiều dọc trong khung
        children: [
          // Icon minh họa
          Icon(
            Icons.bookmark_border,
            size: 80, // Kích thước icon lớn để dễ thấy
            color: Colors.grey[400], // Màu xám nhạt
          ),

          const SizedBox(height: 16),

          // Tiêu đề chính
          Text(
            'Chưa có bài viết nào',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          // Dòng mô tả phụ
          Text(
            'Lưu bài viết vào bộ sưu tập này',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
