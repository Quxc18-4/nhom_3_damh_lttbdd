// File: screens/startup/splashScreen.dart

import 'package:flutter/material.dart'; // Thư viện chính của Flutter
import 'dart:async'; // Dùng cho Timer
// Cập nhật đường dẫn cho đúng
import 'package:nhom_3_damh_lttbdd/screens/authentication/login/loginScreen.dart'; // Màn hình đăng nhập
// Import widget đã tách
import 'widget/splash_widgets.dart'; // Các widget con: AnimatedLogo, Slogan

class SplashScreen extends StatefulWidget { // Màn hình splash
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState(); // Tạo state
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin { // Dùng để điều khiển animation
  late AnimationController _controller; // Bộ điều khiển animation
  late Animation<double> _fadeAnimation; // Animation mờ dần
  late Animation<double> _scaleAnimation; // Animation phóng to

  @override
  void initState() { // Khởi tạo khi widget được tạo
    super.initState();

    _controller = AnimationController( // Khởi tạo controller
      duration: const Duration(milliseconds: 1500), // Thời gian animation 1.5s
      vsync: this, // Cung cấp ticker
    );

    _fadeAnimation = Tween<double>( // Animation từ 0.0 → 1.0
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn)); // Hiệu ứng mờ vào

    _scaleAnimation = Tween<double>( // Animation từ 0.5 → 1.0
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)); // Hiệu ứng bật ra

    _controller.forward(); // Bắt đầu chạy animation

    // Điều hướng sau 3 giây
    Timer(const Duration(seconds: 3), () { // Tạo timer 3 giây
      if (mounted) { // Kiểm tra widget còn tồn tại
        // Thêm kiểm tra 'mounted'
        Navigator.of(context).pushReplacement( // Thay thế màn hình hiện tại
          MaterialPageRoute(builder: (context) => const LoginScreen()), // Sang màn hình Login
        );
      }
    });
  }

  @override
  void dispose() { // Dọn dẹp khi widget bị hủy
    _controller.dispose(); // Giải phóng controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Scaffold(
      body: Container( // Toàn bộ nền
        width: double.infinity, // Chiếm toàn bộ chiều rộng
        decoration: const BoxDecoration( // Nền gradient
          gradient: LinearGradient(
            begin: Alignment.topCenter, // Từ trên
            end: Alignment.bottomCenter, // Xuống dưới
            colors: [Color(0xFFE3F2FD), Color(0xFFFFE0B2), Color(0xFFFFCC80)], // 3 màu chuyển dần
          ),
        ),
        child: Column( // Cột dọc chính
          mainAxisAlignment: MainAxisAlignment.center, // Căn giữa
          children: [
            const Spacer(flex: 2), // Khoảng trống trên (2 phần)

            // === SỬ DỤNG WIDGET MỚI ===
            AnimatedLogo( // Widget logo có animation
              fadeAnimation: _fadeAnimation, // Truyền animation mờ
              scaleAnimation: _scaleAnimation, // Truyền animation scale
            ),

            // =========================
            const Spacer(flex: 1), // Khoảng trống giữa logo và slogan

            // === SỬ DỤNG WIDGET MỚI ===
            const Slogan(), // Widget slogan

            // =========================
            const SizedBox(height: 60), // Khoảng cách cố định
            const CircularProgressIndicator( // Vòng loading
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)), // Màu cam
              strokeWidth: 3, // Độ dày vòng
            ),
            const Spacer(flex: 1), // Khoảng trống dưới
          ],
        ),
      ),
    );
  }
}

// (Xóa class ArcPainter vì nó không được sử dụng trong file này)