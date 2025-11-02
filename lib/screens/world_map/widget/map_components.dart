// File: screens/world_map/widget/map_components.dart

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Widget hiển thị loading (giống code của bạn)
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Đang tải bản đồ và vị trí...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Lớp phủ mờ khi chọn 1 điểm
class MapBlurOverlay extends StatelessWidget {
  final VoidCallback onTap;
  const MapBlurOverlay({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onTap, // Bấm mờ -> ẩn marker đỏ
        behavior: HitTestBehavior.opaque,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.black.withOpacity(0.1)),
        ),
      ),
    );
  }
}
