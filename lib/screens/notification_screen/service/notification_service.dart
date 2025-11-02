// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nhom_3_damh_lttbdd/model/notificationModel.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';

/// Service xử lý thông báo của người dùng
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cache user để tránh fetch nhiều lần
  final Map<String, User> _userCache = {};

  /// 🔹 Lấy user theo id và cache lại
  /// Nếu đã có trong cache, trả về luôn
  /// Nếu không tồn tại, trả về user mặc định
  Future<User> fetchAndCacheUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final user = User.fromDoc(userDoc);
        _userCache[userId] = user; // cache lại
        return user;
      }
    } catch (e) {
      debugPrint('Error fetching user $userId: $e');
    }

    // Trả về user mặc định nếu không tìm thấy
    return User(
      id: userId,
      name: 'Người dùng không tồn tại',
      avatarUrl: 'assets/images/default_avatar.png',
    );
  }

  /// 🔹 Đánh dấu một thông báo là đã đọc
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint("Lỗi đánh dấu đã đọc: $e");
    }
  }

  /// 🔹 Ánh xạ dữ liệu Notification với User (người gửi)
  /// docs: danh sách các document notification từ Firestore
  /// Trả về danh sách NotificationModel kèm thông tin sender
  Future<List<NotificationModel>> mapNotificationsWithUsers(
    List<QueryDocumentSnapshot> docs,
  ) async {
    // map từng document thành NotificationModel có kèm sender
    final futures = docs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      final senderId = data['senderId'] as String? ?? '';

      User sender = User.empty();
      if (senderId.isNotEmpty) {
        // lấy user từ cache hoặc Firestore
        sender = await fetchAndCacheUser(senderId);
      }

      // Tạo base notification từ Firestore
      final baseNotification = NotificationModel.fromFirestore(doc);

      // Trả về notification mới có sender
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

    // đợi tất cả future hoàn thành
    return await Future.wait(futures);
  }
}
