import 'package:flutter/material.dart';

/// Widget hiển thị một thẻ thống kê (thành tích)
/// Có thể dùng cho số lượng bài viết, lượt thích, điểm đến, ...
class StatCard extends StatelessWidget {
  final String value; // Giá trị chính (ví dụ: 120, 1.5K)
  final String label; // Nhãn (ví dụ: "Bài viết", "Lượt thích")
  final Color color; // Màu nền thẻ

  const StatCard({
    Key? key,
    required this.value,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, // Không đổ bóng
      color: color, // Màu nền
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Bo tròn các góc
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
          mainAxisAlignment:
              MainAxisAlignment.center, // Căn giữa theo chiều dọc
          children: [
            // Giá trị chính
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // Nhãn
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
