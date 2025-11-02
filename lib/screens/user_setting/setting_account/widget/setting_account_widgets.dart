// File: screens/user_setting/setting_account/widget/setting_account_widgets.dart

import 'package:flutter/material.dart'; // Thư viện chính của Flutter

/// Tiêu đề của một nhóm menu
Widget buildSectionTitle(String title) { // Widget tiêu đề nhóm (ví dụ: "Tài khoản", "Bảo mật")
  return Padding( // Padding dưới và trái
    padding: const EdgeInsets.only(bottom: 8.0, left: 4.0), // Cách dưới 8dp, trái 4dp
    child: Text(
      title, // Nội dung tiêu đề
      style: const TextStyle(
        fontSize: 16, // Cỡ chữ 16
        fontWeight: FontWeight.bold, // In đậm
        color: Colors.black54, // Màu đen nhạt
      ),
    ),
  );
}

/// Một thẻ bao bọc danh sách các mục có thể bấm vào
Widget buildClickableCard(List<Widget> items) { // Widget khung chứa nhiều menu item
  return Container( // Khung bao bọc
    decoration: BoxDecoration( // Trang trí khung
      color: Colors.white, // Nền trắng
      borderRadius: BorderRadius.circular(16), // Bo góc 16dp
      boxShadow: [ // Bóng đổ nhẹ
        BoxShadow(
          color: Colors.grey.withOpacity(0.1), // Màu xám mờ 10%
          blurRadius: 10, // Độ mờ bóng
          offset: const Offset(0, 4), // Dịch bóng xuống 4dp
        ),
      ],
    ),
    child: Column(children: items), // Danh sách các item bên trong
  );
}

/// Một hàng (row) trong menu
Widget buildMenuItem({ // Widget một mục trong menu
  required IconData icon, // Icon bên trái
  required String title, // Tiêu đề
  required VoidCallback onTap, // Hàm gọi khi nhấn
  String? trailingText, // Văn bản bên phải (nếu có)
  Color? textColor, // Màu chữ (nếu có)
  bool showDivider = true, // Hiển thị gạch ngang (mặc định có)
}) {
  return Material( // Material cho hiệu ứng ripple
    color: Colors.transparent, // Nền trong suốt
    child: InkWell( // Vùng nhấn với hiệu ứng gợn sóng
      onTap: onTap, // Gọi hàm khi nhấn
      borderRadius: BorderRadius.circular(16), // Bo góc vùng nhấn
      child: Column(
        children: [
          Padding( // Padding cho nội dung item
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Trái-phải 16dp, trên-dưới 14dp
            child: Row( // Dòng ngang: icon + title + trailing + mũi tên
              children: [
                Icon(icon, color: textColor ?? Colors.grey[600]), // Icon với màu tùy chỉnh
                const SizedBox(width: 16), // Khoảng cách giữa icon và chữ
                Expanded( // Chiếm phần còn lại
                  child: Text(
                    title, // Tiêu đề mục
                    style: TextStyle(
                      fontSize: 16, // Cỡ chữ
                      color: textColor ?? Colors.black87, // Màu chữ
                    ),
                  ),
                ),
                if (trailingText != null) // Nếu có văn bản bên phải
                  Text(
                    trailingText, // Hiển thị
                    style: const TextStyle(fontSize: 16, color: Colors.grey), // Màu xám
                  ),
                const SizedBox(width: 8), // Khoảng cách trước mũi tên
                Icon( // Mũi tên chỉ sang phải
                  Icons.arrow_forward_ios,
                  size: 16, // Nhỏ
                  color: Colors.grey[400], // Màu xám nhạt
                ),
              ],
            ),
          ),
          if (showDivider) // Nếu cần gạch ngang phân cách
            Padding(
              padding: const EdgeInsets.only(left: 50.0), // Căn lề trái từ vị trí icon
              child: Divider(height: 1, thickness: 1, color: Colors.grey[100]), // Gạch mỏng
            ),
        ],
      ),
    ),
  );
}