// File: screens/startup/widget/splash_widgets.dart

import 'package:flutter/material.dart';

/// Widget hiển thị Logo và Tên App (với animation)
class AnimatedLogo extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;

  const AnimatedLogo({
    Key? key,
    required this.fadeAnimation,
    required this.scaleAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          ScaleTransition(
            scale: scaleAnimation,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Tên app
          Text(
            'Triply',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              fontFamily: 'Brush Script MT',
              fontStyle: FontStyle.italic,
              color: Colors.black87,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị Slogan
class Slogan extends StatelessWidget {
  const Slogan({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            'Chuyến đi của bạn bắt đầu từ một cú chạm',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
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
