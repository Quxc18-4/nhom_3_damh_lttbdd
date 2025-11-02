import 'package:flutter/material.dart';

/// Widget hiển thị BottomSheet để người dùng chọn loại bài viết muốn tạo
class CreatePostBottomSheet extends StatelessWidget {
  // Callbacks tương ứng với mỗi loại bài viết
  final VoidCallback onBlogTap;
  final VoidCallback onCheckinTap;
  final VoidCallback onQuestionTap;

  const CreatePostBottomSheet({
    Key? key,
    required this.onBlogTap,
    required this.onCheckinTap,
    required this.onQuestionTap,
  }) : super(key: key);

  /// 🔹 Hàm tiện ích để show BottomSheet
  static void show(
    BuildContext context, {
    required VoidCallback onBlogTap,
    required VoidCallback onCheckinTap,
    required VoidCallback onQuestionTap,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // để bo góc đẹp hơn
      builder: (context) => CreatePostBottomSheet(
        onBlogTap: onBlogTap,
        onCheckinTap: onCheckinTap,
        onQuestionTap: onQuestionTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        // Bo tròn góc trên của BottomSheet
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // chiếm đúng kích thước nội dung
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tiêu đề và nút đóng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tạo bài viết',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context), // đóng BottomSheet
              ),
            ],
          ),
          const Divider(height: 10),

          // Các tùy chọn tạo bài viết
          _buildOptionTile(
            icon: Icons.edit_note,
            label: 'Blog',
            subLabel: 'Viết bài',
            onTap: onBlogTap,
          ),
          _buildOptionTile(
            icon: Icons.camera_alt_outlined,
            label: 'Checkin',
            onTap: onCheckinTap,
          ),
          _buildOptionTile(
            icon: Icons.help_outline,
            label: 'Đặt câu hỏi',
            onTap: onQuestionTap,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// 🔹 Widget riêng cho từng option trong BottomSheet
  /// icon: biểu tượng hiển thị
  /// label: tên chính
  /// subLabel: mô tả ngắn (không bắt buộc)
  /// onTap: callback khi nhấn
  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? subLabel,
  }) {
    return InkWell(
      onTap: onTap, // xử lý nhấn
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subLabel != null)
                  Text(
                    subLabel,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
