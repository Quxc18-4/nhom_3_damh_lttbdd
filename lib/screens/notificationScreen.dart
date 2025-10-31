import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nhom_3_damh_lttbdd/model/notificationModel.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/personalProfileScreen.dart';
import 'postDetailScreen.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;

  const NotificationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, User> _userCache = {};

  @override
  void initState() {
    super.initState();
  }

  // ===================================================================
  // USER CACHE & FETCH
  // ===================================================================

  Future<User> _fetchAndCacheUser(String userId) async {
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

  // ===================================================================
  // ACTIONS
  // ===================================================================

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint("Lỗi đánh dấu đã đọc: $e");
    }
  }

  void _navigateToPostDetail(
    String notificationId,
    NotificationModel notification,
  ) async {
    _markAsRead(notificationId);

    if (notification.referenceId.isNotEmpty && notification.type != 'FOLLOW') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PostDetailScreen(reviewId: notification.referenceId),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chuyển đến Profile.")));
      if (notification.senderId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PersonalProfileScreen(userId: notification.senderId),
          ),
        );
      }
    }
  }

  // ===================================================================
  // WIDGET BUILDERS
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải thông báo: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notificationDocs = snapshot.data?.docs ?? [];

          if (notificationDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn không có thông báo nào.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<NotificationModel>>(
            future: _mapNotificationsWithUsers(notificationDocs),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasError || !userSnapshot.hasData) {
                return const Center(child: Text('Lỗi hiển thị dữ liệu.'));
              }

              final notifications = userSnapshot.data!;

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return _buildNotificationItem(notif);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<NotificationModel>> _mapNotificationsWithUsers(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final futures = docs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      final senderId = data['senderId'] as String? ?? '';

      User sender = User.empty();
      if (senderId.isNotEmpty) {
        sender = await _fetchAndCacheUser(senderId);
      }

      final baseNotification = NotificationModel.fromFirestore(doc);

      // TÁI TẠO (COPY) MODEL VỚI THÔNG TIN SENDER ĐÃ FETCH ĐƯỢC
      return NotificationModel(
        id: baseNotification.id,
        userId: baseNotification.userId,
        senderId: baseNotification.senderId,
        type: baseNotification.type,
        message: baseNotification.message,
        referenceId: baseNotification.referenceId,
        createdAt: baseNotification.createdAt,
        isRead: baseNotification.isRead,
        sender: sender, // Gán đối tượng User đã fetch
      );
    }).toList();

    return await Future.wait(futures);
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    // Định dạng thời gian: 21:02 31/10 (Giống hình ảnh)
    final timeFormat = DateFormat('HH:mm dd/MM');
    final timeAgo = timeFormat.format(notification.createdAt);

    return InkWell(
      onTap: () => _navigateToPostDetail(notification.id, notification),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // Màu nền chưa đọc: xanh nhạt (giống ảnh)
          color: notification.isRead ? Colors.white : Colors.blue.shade50,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar người gửi
            CircleAvatar(
              radius: 20,
              backgroundImage: notification.sender.avatarUrl.startsWith('http')
                  ? NetworkImage(notification.sender.avatarUrl)
                  : AssetImage(notification.sender.avatarUrl) as ImageProvider,
            ),
            const SizedBox(width: 12),

            // Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên người gửi (Bold) + Nội dung (Không có Circle Avatar cho badge ở đây)
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        color: Colors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: notification.sender.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ' ${notification.message}',
                          style: const TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Thời gian (Nhỏ và màu xám)
                  Text(
                    timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Icon trạng thái đã đọc (chỉ hiện khi chưa đọc)
            if (!notification.isRead)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: Colors.blue.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
