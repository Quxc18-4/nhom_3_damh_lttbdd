import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Service xử lý thông báo (notifications)
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Tạo một thông báo mới
  /// recipientId: ID người nhận
  /// senderId: ID người gửi
  /// reviewId: ID bài viết liên quan (nếu có)
  /// type: loại thông báo (like, comment, follow, ...)
  /// message: nội dung thông báo hiển thị
  Future<void> createNotification({
    required String recipientId,
    required String senderId,
    required String reviewId,
    required String type,
    required String message,
  }) async {
    // 🔹 Không tạo thông báo nếu gửi cho chính mình hoặc thiếu thông tin
    if (recipientId == senderId || recipientId.isEmpty || senderId.isEmpty) {
      return;
    }

    try {
      // 🔹 Thêm document mới vào collection 'notifications'
      await _firestore.collection('notifications').add({
        'userId': recipientId, // ID người nhận thông báo
        'senderId': senderId, // ID người gửi
        'referenceId': reviewId, // ID bài viết liên quan
        'type': type, // Loại thông báo
        'message': message, // Nội dung thông báo
        'isRead': false, // Mặc định chưa đọc
        'createdAt': FieldValue.serverTimestamp(), // Thời gian tạo (server)
      });
    } catch (e) {
      // 🔹 Log lỗi nếu có
      debugPrint("Lỗi tạo thông báo: $e");
    }
  }
}
