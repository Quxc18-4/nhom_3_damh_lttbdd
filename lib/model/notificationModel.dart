import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart'; // Import User model

class NotificationModel {
  final String id;
  final String userId; // ID người nhận
  final String senderId;
  final String type; // e.g., 'COMMENT', 'LIKE', 'FOLLOW'
  final String message;
  final String referenceId; // e.g., reviewId, postId
  final DateTime createdAt;
  final bool isRead;
  final User sender; // 🆕 THUỘC TÍNH MỚI: Đối tượng người gửi

  NotificationModel({
    required this.id,
    required this.userId,
    required this.senderId,
    required this.type,
    required this.message,
    required this.referenceId,
    required this.createdAt,
    required this.isRead,
    required this.sender, // 🆕 Yêu cầu sender khi khởi tạo
  });

  // Constructor factory đơn giản, chỉ lấy từ Firestore (không cần sender ở đây)
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final Timestamp timestamp = data['createdAt'] ?? Timestamp.now();

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      senderId: data['senderId'] ?? '',
      type: data['type'] ?? 'UNKNOWN',
      message: data['message'] ?? '',
      referenceId: data['referenceId'] ?? '',
      createdAt: timestamp.toDate(),
      isRead: data['isRead'] ?? false,
      // Gán sender tạm thời là User.empty() khi khởi tạo ban đầu
      sender: User.empty(),
    );
  }
}
