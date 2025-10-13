import 'package:flutter/material.dart';

// Đặt widget này vào file following_tab_content.dart
class FollowingTabContent extends StatelessWidget {
  const FollowingTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu cho danh sách người theo dõi
    final List<Map<String, dynamic>> followingData = [
      {
        'name': 'Khoai Lang thang',
        'role': 'Video Creator/Blogger • 2.1M followers',
        'avatar': 'assets/images/khoai_avatar.png', // Thay bằng ảnh thực
      },
      {
        'name': 'Khoa Pug',
        'role': 'Video Creator/Blogger • 3M followers',
        'avatar': 'assets/images/khoa_avatar.png', // Thay bằng ảnh thực
      },
      {
        'name': 'Nguyễn Văn A',
        'role': 'Travel Enthusiast • 500K followers',
        'avatar': 'assets/images/nguyen_a_avatar.png',
      },
      // Thêm nhiều mục hơn để kiểm tra cuộn
      {
        'name': 'Trần Thị B',
        'role': 'Food Reviewer • 1.1M followers',
        'avatar': 'assets/images/tran_b_avatar.png',
      },
      {
        'name': 'Lê Văn C',
        'role': 'Photographer • 800K followers',
        'avatar': 'assets/images/le_c_avatar.png',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: followingData.length,
      itemBuilder: (context, index) {
        final item = followingData[index];
        return _buildFollowingItem(context, item);
      },
    );
  }

  Widget _buildFollowingItem(BuildContext context, Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Avatar (Hình ảnh đại diện)
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            // Sử dụng Image.asset nếu bạn có ảnh trong assets
            // child: Image.asset(item['avatar']),
            // Nếu không có ảnh, dùng placeholder
            child: const Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(width: 12),

          // Tên và Vai trò
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['role']!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Nút "Đang theo dõi" (Unfollow button)
          ElevatedButton(
            onPressed: () {
              // TODO: Thêm logic hủy theo dõi
              print('Hủy theo dõi ${item['name']}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, // Nền trắng
              foregroundColor: Colors.orange, // Chữ cam
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.orange[400]!), // Viền cam
              ),
            ),
            child: const Text(
              'Đang theo dõi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}