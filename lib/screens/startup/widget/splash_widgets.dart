// File: screens/startup/widget/splash_widgets.dart

import 'package:flutter/material.dart'; // Thư viện chính của Flutter

/// Widget hiển thị Logo và Tên App (với animation)
class AnimatedLogo extends StatelessWidget { // Widget có animation cho logo và tên app
  final Animation<double> fadeAnimation; // Animation làm mờ dần (opacity)
  final Animation<double> scaleAnimation; // Animation phóng to/thu nhỏ (scale)

  const AnimatedLogo({ // Constructor
    Key? key,
    required this.fadeAnimation,
    required this.scaleAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return FadeTransition( // Áp dụng hiệu ứng mờ dần
      opacity: fadeAnimation, // Dùng animation opacity
      child: Column( // Cột dọc chứa logo + tên app
        mainAxisAlignment: MainAxisAlignment.center, // Căn giữa dọc
        children: [
          // Logo
          ScaleTransition( // Áp dụng hiệu ứng phóng to/thu nhỏ
            scale: scaleAnimation, // Dùng animation scale
            child: Container( // Khung tròn chứa logo
              width: 200, // Chiều rộng 200dp
              height: 200, // Chiều cao 200dp
              decoration: BoxDecoration( // Trang trí khung
                color: Colors.white.withOpacity(0.3), // Nền trắng mờ 30%
                shape: BoxShape.circle, // Hình tròn
              ),
              child: ClipOval( // Cắt hình tròn
                child: Image.asset( // Hiển thị ảnh từ assets
                  'assets/images/logo.png', // Đường dẫn ảnh logo
                  width: 180, // Kích thước ảnh
                  height: 180,
                  fit: BoxFit.cover, // Cắt vừa khung
                  errorBuilder: (context, error, stackTrace) { // Nếu lỗi tải ảnh
                    return const Icon(
                      Icons.image_not_supported, // Icon báo lỗi
                      size: 80,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 30), // Khoảng cách giữa logo và tên app
          // Tên app
          Text( // Hiển thị chữ "Triply"
            'Triply',
            style: TextStyle(
              fontSize: 56, // Cỡ chữ lớn
              fontWeight: FontWeight.bold, // In đậm
              fontFamily: 'Brush Script MT', // Font chữ viết tay
              fontStyle: FontStyle.italic, // Nghiêng
              color: Colors.black87, // Màu đen nhạt
              letterSpacing: 2, // Khoảng cách giữa các chữ cái
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị Slogan
class Slogan extends StatelessWidget { // Widget hiển thị slogan
  const Slogan({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Padding( // Padding hai bên
      padding: const EdgeInsets.symmetric(horizontal: 40), // Cách lề trái/phải 40dp
      child: Column( // Cột dọc chứa 2 dòng slogan
        children: [
          Text( // Dòng 1
            'Chuyến đi của bạn bắt đầu từ một cú chạm',
            textAlign: TextAlign.center, // Căn giữa
            style: TextStyle(
              fontSize: 16, // Cỡ chữ
              color: Colors.black87, // Màu chữ
              fontWeight: FontWeight.w500, // Độ đậm vừa
            ),
          ),
          const SizedBox(height: 8), // Khoảng cách giữa 2 dòng
          Text( // Dòng 2
            'Và Triply sẽ đồng hành cùng bạn trên từng cung đường!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}