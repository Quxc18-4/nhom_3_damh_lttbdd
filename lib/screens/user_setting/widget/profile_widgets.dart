// File: screens/user_setting/widget/profile_widgets.dart

import 'package:flutter/material.dart'; // Thư viện chính của Flutter

// === WIDGET 1: THẺ THÔNG TIN NGƯỜI DÙNG ===
class UserInfoCard extends StatelessWidget { // Widget hiển thị thông tin người dùng (avatar, tên, email, rank)
  final String avatarPath; // Đường dẫn ảnh đại diện (có thể là asset hoặc URL)
  final String userName; // Tên người dùng
  final String userEmail; // Email người dùng
  final String userRank; // Cấp bậc (ví dụ: "VIP", "Member")
  final VoidCallback onViewProfile; // Hàm gọi khi nhấn nút "Xem hồ sơ"

  const UserInfoCard({ // Constructor
    Key? key,
    required this.avatarPath,
    required this.userName,
    required this.userEmail,
    required this.userRank,
    required this.onViewProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Container( // Khung chính
      padding: const EdgeInsets.all(20), // Padding đều 20dp
      decoration: BoxDecoration( // Trang trí khung
        color: Colors.blue.shade700, // Nền xanh đậm
        borderRadius: BorderRadius.circular(20), // Bo góc 20dp
        boxShadow: [ // Bóng đổ
          BoxShadow(
            color: Colors.blue.withOpacity(0.3), // Bóng xanh mờ
            blurRadius: 10, // Độ mờ
            offset: const Offset(0, 5), // Dịch bóng xuống 5dp
          ),
        ],
      ),
      child: Column( // Cột dọc: avatar + info + nút
        children: [
          Row( // Dòng ngang: avatar + thông tin
            children: [
              CircleAvatar( // Avatar tròn
                radius: 35, // Bán kính 35dp
                backgroundColor: Colors.grey.shade200, // Nền xám nếu không có ảnh
                backgroundImage: avatarPath.startsWith('http') // Kiểm tra là URL
                    ? NetworkImage(avatarPath) // Tải ảnh từ mạng
                    : AssetImage(avatarPath) as ImageProvider, // Dùng ảnh asset
              ),
              const SizedBox(width: 15), // Khoảng cách
              Expanded( // Chiếm phần còn lại
                child: Column( // Cột dọc: tên, email, rank
                  crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
                  children: [
                    Text( // Tên người dùng
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1, // Chỉ 1 dòng
                      overflow: TextOverflow.ellipsis, // Cắt nếu quá dài
                    ),
                    const SizedBox(height: 4), // Khoảng cách
                    Text( // Email
                      userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8), // Mờ 80%
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6), // Khoảng cách
                    Container( // Khung rank
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration( // Trang trí
                        color: Colors.black.withOpacity(0.2), // Nền đen mờ
                        borderRadius: BorderRadius.circular(12), // Bo góc
                      ),
                      child: Text( // Văn bản rank
                        userRank,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // Khoảng cách
          SizedBox( // Nút "Xem hồ sơ"
            width: double.infinity, // Chiếm toàn bộ chiều rộng
            child: ElevatedButton( // Nút nổi
              onPressed: onViewProfile, // Gọi hàm khi nhấn
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Nền trắng
                foregroundColor: Colors.blue.shade700, // Chữ xanh
                shape: RoundedRectangleBorder( // Bo góc
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14), // Padding dọc
              ),
              child: const Text(
                'Xem hồ sơ của tôi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === WIDGET 2: BANNER VIP ===
class VipBanner extends StatelessWidget { // Widget quảng cáo nâng cấp VIP
  const VipBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Container( // Khung banner
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Padding
      decoration: BoxDecoration( // Trang trí
        color: Colors.orange.shade50, // Nền cam nhạt
        borderRadius: BorderRadius.circular(16), // Bo góc
        border: Border.all(color: Colors.orange.shade200), // Viền cam
      ),
      child: Row( // Dòng ngang: icon + text
        children: [
          Icon(Icons.star, color: Colors.orange.shade700), // Icon sao
          const SizedBox(width: 12), // Khoảng cách
          const Expanded( // Văn bản quảng cáo
            child: Text.rich(
              TextSpan(
                text: "Nâng cấp ", // Phần 1
                style: TextStyle(color: Colors.black87),
                children: [
                  TextSpan( // Phần 2: TriplyVIP
                    text: 'TriplyVIP ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: 'để tận hưởng nhiều ưu đãi hơn.'), // Phần 3
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === WIDGET 3: TIÊU ĐỀ PHẦN ===
class SectionTitle extends StatelessWidget { // Tiêu đề cho các nhóm menu
  final String title; // Nội dung tiêu đề
  const SectionTitle(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Padding( // Padding dưới và trái
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title, // Hiển thị tiêu đề
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// === WIDGET 4: THẺ CHỨA CÁC MỤC ===
class ClickableCard extends StatelessWidget { // Khung chứa nhiều MenuItem
  final List<Widget> items; // Danh sách các item
  const ClickableCard(this.items, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Container( // Khung bao bọc
      decoration: BoxDecoration( // Trang trí
        color: Colors.white, // Nền trắng
        borderRadius: BorderRadius.circular(16), // Bo góc
        boxShadow: [ // Bóng đổ nhẹ
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: items), // Hiển thị danh sách item
    );
  }
}

// === WIDGET 5: MỘT MỤC TRONG THẺ ===
class MenuItem extends StatelessWidget { // Một mục trong menu
  final IconData icon; // Icon bên trái
  final String title; // Tiêu đề
  final VoidCallback onTap; // Hàm gọi khi nhấn
  final bool showDivider; // Hiển thị gạch ngang dưới không

  const MenuItem({ // Constructor
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.showDivider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Column( // Cột dọc: nội dung + gạch ngang
      children: [
        Material( // Material cho hiệu ứng ripple
          color: Colors.transparent, // Nền trong suốt
          child: InkWell( // Vùng nhấn
            onTap: onTap, // Gọi hàm khi nhấn
            borderRadius: BorderRadius.circular(16), // Bo góc vùng nhấn
            child: Padding( // Padding nội dung
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row( // Dòng ngang: icon + title + mũi tên
                children: [
                  Icon(icon, color: Colors.grey[600]), // Icon
                  const SizedBox(width: 16), // Khoảng cách
                  Expanded( // Tiêu đề
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon( // Mũi tên
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) // Nếu cần gạch ngang
          Padding(
            padding: const EdgeInsets.only(left: 50.0), // Căn lề từ vị trí icon
            child: Divider(height: 1, thickness: 1, color: Colors.grey[100]), // Gạch mỏng
          ),
      ],
    );
  }
}