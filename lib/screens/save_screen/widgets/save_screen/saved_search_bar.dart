import 'package:flutter/material.dart';

/// Thanh tìm kiếm cho màn hình "Đã lưu"
/// Cho phép người dùng nhập từ khóa để lọc danh sách bài viết / bộ sưu tập.
class SavedSearchBar extends StatelessWidget {
  const SavedSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding bao quanh nội dung thanh tìm kiếm
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      // Trang trí viền, màu nền, bo góc
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!),
      ),

      // Hàng ngang gồm: icon tìm kiếm - textfield - icon bộ lọc
      child: Row(
        children: [
          // 🔍 Icon tìm kiếm
          const Icon(Icons.search, color: Colors.grey, size: 24),

          const SizedBox(width: 10),

          // 📄 Ô nhập từ khóa
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm đã lưu...',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 16),
              onChanged: (value) {
                // TODO: Ở đây bạn có thể gọi hàm tìm kiếm trong Firestore
                // ví dụ: controller.searchSavedItems(value);
              },
            ),
          ),

          // ⚙️ Icon bộ lọc
          GestureDetector(
            onTap: () {
              // TODO: mở modal lọc (ví dụ: lọc theo thể loại hoặc ngày lưu)
            },
            child: const Icon(Icons.filter_list, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
