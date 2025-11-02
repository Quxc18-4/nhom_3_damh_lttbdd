import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget hiển thị SliverAppBar cho trang chi tiết album.
/// - Có ảnh bìa động (có thể đổi).
/// - Có menu chỉnh sửa, xóa, hoặc đổi ảnh bìa.
/// - Hoạt động mượt trong CustomScrollView.
class AlbumSliverAppBar extends StatelessWidget {
  /// Tiêu đề album (hiển thị trên AppBar)
  final String albumTitle;

  /// Đường dẫn ảnh bìa (lưu trong Firestore)
  final String coverUrl;

  /// Callback khi người dùng chọn “Chỉnh sửa thông tin album”
  final VoidCallback onEdit;

  /// Callback khi người dùng chọn “Đổi ảnh bìa”
  final VoidCallback onChangeCover;

  /// Callback khi người dùng chọn “Xóa album”
  final VoidCallback onDelete;

  const AlbumSliverAppBar({
    Key? key,
    required this.albumTitle,
    required this.coverUrl,
    required this.onEdit,
    required this.onChangeCover,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250, // Chiều cao khi mở rộng tối đa
      pinned: true, // Giữ AppBar cố định khi cuộn
      backgroundColor: Colors.orange,

      // Phần co giãn linh hoạt (có ảnh nền + tiêu đề)
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          albumTitle,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Ảnh bìa album (nếu lỗi thì hiển thị icon thay thế)
            Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.orange.shade300,
                  child: const Icon(
                    Icons.photo_library,
                    size: 80,
                    color: Colors.white,
                  ),
                );
              },
            ),

            // Lớp phủ mờ ở phía dưới để chữ dễ đọc hơn
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ],
        ),
      ),

      // Nút menu (3 chấm) để thực hiện hành động
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            // Xử lý sự kiện menu
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            } else if (value == 'change_cover') {
              onChangeCover();
            }
          },

          // Danh sách các lựa chọn trong menu
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa thông tin'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'change_cover',
              child: Row(
                children: [
                  Icon(Icons.image, size: 20),
                  SizedBox(width: 8),
                  Text('Đổi ảnh bìa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa bộ sưu tập', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
