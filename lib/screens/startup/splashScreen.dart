// File: screens/startup/splashScreen.dart

import 'package:flutter/material.dart';
import 'dart:async';
// Cập nhật đường dẫn cho đúng
import 'package:nhom_3_damh_lttbdd/screens/authentication/login/loginScreen.dart';
// Import widget đã tách
import 'widget/splash_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Điều hướng sau 3 giây
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Thêm kiểm tra 'mounted'
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFFFE0B2), Color(0xFFFFCC80)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // === SỬ DỤNG WIDGET MỚI ===
            AnimatedLogo(
              fadeAnimation: _fadeAnimation,
              scaleAnimation: _scaleAnimation,
            ),

            // =========================
            const Spacer(flex: 1),

            // === SỬ DỤNG WIDGET MỚI ===
            const Slogan(),

            // =========================
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
              strokeWidth: 3,
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}

// (Xóa class ArcPainter vì nó không được sử dụng trong file này)
