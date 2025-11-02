import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tạo thông báo
  Future<void> createNotification({
    required String recipientId,
    required String senderId,
    required String reviewId,
    required String type,
    required String message,
  }) async {
    // Không tạo thông báo nếu gửi cho chính mình
    if (recipientId == senderId || recipientId.isEmpty || senderId.isEmpty) {
      return;
    }

    try {
      await _firestore.collection('notifications').add({
        'userId': recipientId,
        'senderId': senderId,
        'referenceId': reviewId,
        'type': type,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Lỗi tạo thông báo: $e");
    }
  }
}
