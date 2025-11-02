// File: screens/trip_planner/helper/trip_planner_helper.dart

import 'package:flutter/material.dart';

// Ánh xạ màu sắc cho các ngày
final Map<int, ({Color mainColor, Color accentColor})> _dayColors = {
  0: (mainColor: Color(0xFF9933CC), accentColor: Color(0xFFE0B0FF)), // Tím
  1: (mainColor: Color(0xFFFF6699), accentColor: Color(0xFFFFCCF5)), // Hồng
  2: (
    mainColor: Color(0xFF3399FF),
    accentColor: Color(0xFFB0D5FF),
  ), // Xanh dương
  3: (mainColor: Color(0xFF4CAF50), accentColor: Color(0xFFC8E6C9)), // Xanh lá
  4: (mainColor: Color(0xFFFFC107), accentColor: Color(0xFFFFECB3)), // Vàng
  5: (mainColor: Color(0xFFE53935), accentColor: Color(0xFFFFCDD2)), // Đỏ
  6: (
    mainColor: Color(0xFF00BCD4),
    accentColor: Color(0xFFB2EBF2),
  ), // Xanh ngọc
};

/// Lấy cặp màu (main, accent) cho một index (ngày)
({Color mainColor, Color accentColor}) getColorForDay(int index) {
  return _dayColors[index % _dayColors.length]!;
}

/// Chuyển đổi thời gian "hh:mm" sang số phút (dùng để so sánh)
int convertTimeToMinutes(String time) {
  try {
    final parts = time.split(":");
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  } catch (e) {
    return 0; // Trả về 0 nếu định dạng lỗi
  }
}
