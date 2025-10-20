import 'package:flutter/material.dart';

class Activity {
  final String time; // "hh:mm"
  final String title;
  final IconData icon;
  final Color color;
  final String? detail; // Có thể null

  Activity({
    required this.time,
    required this.title,
    required this.icon,
    required this.color,
    this.detail,
  });

  // Chuyển từ JSON (Map)
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      time: json['time'] as String,
      title: json['title'] as String,
      // IconData và Color cần được chuyển đổi
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      color: Color(json['colorValue'] as int),
      detail: json['detail'] as String?,
    );
  }

  // Chuyển sang JSON (Map)
  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'title': title,
      'iconCodePoint': icon.codePoint, // Lưu codePoint của IconData
      'colorValue': color.value, // Lưu giá trị int của Color
      'detail': detail,
    };
  }
}