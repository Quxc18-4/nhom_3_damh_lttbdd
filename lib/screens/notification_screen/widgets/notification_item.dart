// lib/widgets/notification_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nhom_3_damh_lttbdd/model/notificationModel.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm dd/MM');
    final timeAgo = timeFormat.format(notification.createdAt);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue.shade50,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: notification.sender.avatarUrl.startsWith('http')
                  ? NetworkImage(notification.sender.avatarUrl)
                  : AssetImage(notification.sender.avatarUrl) as ImageProvider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 16, height: 1.3),
                      children: [
                        TextSpan(
                          text: notification.sender.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' ${notification.message}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
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
