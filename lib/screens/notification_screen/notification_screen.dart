// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhom_3_damh_lttbdd/model/notificationModel.dart';
import 'package:nhom_3_damh_lttbdd/screens/notification_screen/service/notification_service.dart';
import 'package:nhom_3_damh_lttbdd/screens/notification_screen/widgets/notification_item.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/personalProfileScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/temp/postDetailScreen.dart'
    hide PostDetailScreen;
import 'package:nhom_3_damh_lttbdd/screens/post_detail/post_detail_screen.dart';

/// Màn hình hiển thị danh sách thông báo của người dùng
class NotificationScreen extends StatefulWidget {
  final String userId; // ID người dùng hiện tại

  const NotificationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service =
      NotificationService(); // Service xử lý thông báo
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance

  /// Xử lý khi nhấn vào một thông báo
  void _onNotificationTap(NotificationModel notif) async {
    // Đánh dấu thông báo đã đọc
    await _service.markAsRead(notif.id);

    // Nếu thông báo liên quan đến bài viết và không phải follow
    if (notif.referenceId.isNotEmpty && notif.type != 'FOLLOW') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(reviewId: notif.referenceId),
        ),
      );
    }
    // Nếu thông báo là follow hoặc không liên quan đến bài viết, mở trang cá nhân người gửi
    else if (notif.senderId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PersonalProfileScreen(userId: notif.senderId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'), // Tiêu đề AppBar
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Stream theo dõi realtime collection notifications cho userId
        stream: _firestore
            .collection('notifications')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Nếu có lỗi, hiển thị lỗi
          if (snapshot.hasError)
            return Center(child: Text('Lỗi: ${snapshot.error}'));

          // Khi đang load dữ liệu, hiển thị loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          // Nếu không có thông báo nào
          if (docs.isEmpty) {
            return const Center(child: Text('Không có thông báo nào.'));
          }

          // Map thông báo với dữ liệu người gửi
          return FutureBuilder<List<NotificationModel>>(
            future: _service.mapNotificationsWithUsers(docs),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Nếu lỗi hoặc không có dữ liệu
              if (userSnapshot.hasError || !userSnapshot.hasData) {
                return const Center(child: Text('Lỗi hiển thị dữ liệu.'));
              }

              final notifications = userSnapshot.data!;
              // Hiển thị danh sách thông báo
              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, i) => NotificationItem(
                  notification: notifications[i],
                  onTap: () => _onNotificationTap(notifications[i]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
