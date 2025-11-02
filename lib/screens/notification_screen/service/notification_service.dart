// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nhom_3_damh_lttbdd/model/notificationModel.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, User> _userCache = {};

  /// Lấy user theo id và cache lại để tránh fetch lại nhiều lần
  Future<User> fetchAndCacheUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final user = User.fromDoc(userDoc);
        _userCache[userId] = user;
        return user;
      }
    } catch (e) {
      debugPrint('Error fetching user $userId: $e');
    }

    return User(
      id: userId,
      name: 'Người dùng không tồn tại',
      avatarUrl: 'assets/images/default_avatar.png',
    );
  }

  /// Đánh dấu thông báo là đã đọc
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint("Lỗi đánh dấu đã đọc: $e");
    }
  }

  /// Ánh xạ dữ liệu Notification với User (người gửi)
  Future<List<NotificationModel>> mapNotificationsWithUsers(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final futures = docs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      final senderId = data['senderId'] as String? ?? '';

      User sender = User.empty();
      if (senderId.isNotEmpty) {
        sender = await fetchAndCacheUser(senderId);
      }

      final baseNotification = NotificationModel.fromFirestore(doc);

      return NotificationModel(
        id: baseNotification.id,
        userId: baseNotification.userId,
        senderId: baseNotification.senderId,
        type: baseNotification.type,
        message: baseNotification.message,
        referenceId: baseNotification.referenceId,
        createdAt: baseNotification.createdAt,
        isRead: baseNotification.isRead,
        sender: sender,
      );
    }).toList();

    return await Future.wait(futures);
  }
}
