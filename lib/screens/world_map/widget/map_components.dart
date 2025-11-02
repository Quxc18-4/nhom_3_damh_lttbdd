// File: screens/world_map/widget/map_components.dart

import 'package:flutter/material.dart'; // Import thư viện Material
import 'dart:ui'
    as ui; // Import thư viện 'ui' để dùng ImageFilter (cho hiệu ứng blur)

/// Widget hiển thị loading (giống code của bạn)
// Kiểu dữ liệu: StatelessWidget (Widget không có trạng thái)
// Mục đích: Tái sử dụng UI loading ở màn hình WorldMapScreen.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // `Center` để căn giữa nội dung
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo chiều dọc
        children: [
          CircularProgressIndicator(), // Vòng xoay loading
          SizedBox(height: 16), // Khoảng cách
          Text(
            'Đang tải bản đồ và vị trí...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Lớp phủ mờ khi chọn 1 điểm (khi marker đỏ xuất hiện)
// Kiểu dữ liệu: StatelessWidget
class MapBlurOverlay extends StatelessWidget {
  // Kiểu dữ liệu: VoidCallback (1 hàm không có tham số, không trả về)
  // Mục đích: Định nghĩa hành động khi bấm vào lớp mờ này.
  // Luồng dữ liệu: Được truyền từ `WorldMapScreen`.
  final VoidCallback onTap;
  const MapBlurOverlay({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // `Positioned.fill` làm widget con chiếm toàn bộ không gian của `Stack`.
    return Positioned.fill(
      child: GestureDetector(
        onTap: onTap, // Gắn hàm callback vào sự kiện tap
        behavior:
            HitTestBehavior.opaque, // Đảm bảo bắt được tap ở cả vùng trong suốt
        // `BackdropFilter` áp dụng bộ lọc (ví dụ: blur) cho nội dung *bên dưới* nó.
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3), // Bộ lọc làm mờ
          // `Container` màu đen mờ (0.1) đè lên trên lớp blur
          // để tạo cảm giác tối đi.
          child: Container(color: Colors.black.withOpacity(0.1)),
        ),
      ),
    );
  }
}
