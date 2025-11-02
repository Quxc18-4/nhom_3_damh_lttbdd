import 'package:flutter/material.dart';
import '/model/album_models.dart';

/// Hộp thoại cho phép người dùng chọn ảnh bìa album
/// từ danh sách các bài viết đã lưu (reviews)
class AlbumCoverPickerDialog extends StatelessWidget {
  /// Danh sách các bài viết (SavedReviewItem) có ảnh
  final List<SavedReviewItem> reviews;

  /// Callback được gọi khi người dùng chọn một ảnh
  final Function(String imageUrl) onImageSelected;

  const AlbumCoverPickerDialog({
    Key? key,
    required this.reviews,
    required this.onImageSelected,
  }) : super(key: key);

  /// Hàm tĩnh tiện dụng để hiển thị dialog này từ bất kỳ chỗ nào
  static void show(
    BuildContext context, {
    required List<SavedReviewItem> reviews,
    required Function(String imageUrl) onImageSelected,
  }) {
    // Nếu không có bài viết nào, thông báo lỗi
    if (reviews.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có bài viết nào để chọn ảnh bìa.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Hiển thị modal bottom sheet (hộp thoại trượt từ dưới lên)
    showModalBottomSheet(
      context: context,
      builder: (context) => AlbumCoverPickerDialog(
        reviews: reviews,
        onImageSelected: onImageSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Chiếm 70% chiều cao màn hình
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tiêu đề hộp thoại
          const Text(
            'Chọn ảnh bìa từ bài viết đã lưu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Lưới hiển thị ảnh bìa từ các bài viết
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 cột trong mỗi hàng
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final item = reviews[index];
                return InkWell(
                  onTap: () {
                    // Khi người dùng chọn ảnh => đóng hộp thoại và trả ảnh về
                    Navigator.pop(context);
                    onImageSelected(item.imageUrl);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl, // Hiển thị ảnh bìa
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image), // Khi ảnh lỗi
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
