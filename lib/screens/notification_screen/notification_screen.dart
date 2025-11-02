// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhom_3_damh_lttbdd/model/notificationModel.dart';
import 'package:nhom_3_damh_lttbdd/screens/notification_screen/service/notification_service.dart';
import 'package:nhom_3_damh_lttbdd/screens/notification_screen/widgets/notification_item.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/personalProfileScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/postDetailScreen.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;

  const NotificationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _onNotificationTap(NotificationModel notif) async {
    await _service.markAsRead(notif.id);

    if (notif.referenceId.isNotEmpty && notif.type != 'FOLLOW') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(reviewId: notif.referenceId),
        ),
      );
    } else if (notif.senderId.isNotEmpty) {
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
          if (snapshot.hasError)
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Không có thông báo nào.'));
          }

          return FutureBuilder<List<NotificationModel>>(
            future: _service.mapNotificationsWithUsers(docs),
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
