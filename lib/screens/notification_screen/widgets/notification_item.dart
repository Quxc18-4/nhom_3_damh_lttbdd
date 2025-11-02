import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nhom_3_damh_lttbdd/model/notificationModel.dart';

/// Widget hiển thị một item thông báo
class NotificationItem extends StatelessWidget {
  // Dữ liệu thông báo
  final NotificationModel notification;
  // Callback khi nhấn vào thông báo
  final VoidCallback onTap;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Định dạng thời gian hiển thị cho thông báo
    final timeFormat = DateFormat('HH:mm dd/MM');
    final timeAgo = timeFormat.format(notification.createdAt);

    return InkWell(
      onTap: onTap, // Khi nhấn vào item sẽ gọi callback
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // Nếu chưa đọc thì nền xanh nhạt, đã đọc thì trắng
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue.shade50,
          // Viền dưới màu xám nhạt để phân tách item
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar người gửi thông báo
            CircleAvatar(
              radius: 20,
              backgroundImage: notification.sender.avatarUrl.startsWith('http')
                  ? NetworkImage(
                      notification.sender.avatarUrl,
                    ) // Load ảnh từ URL
                  : AssetImage(notification.sender.avatarUrl)
                        as ImageProvider, // Load ảnh từ assets
            ),
            const SizedBox(width: 12), // Khoảng cách giữa avatar và nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nội dung thông báo: tên người gửi + message
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 16, height: 1.3),
                      children: [
                        // Tên người gửi in đậm
                        TextSpan(
                          text: notification.sender.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // Nội dung thông báo bình thường
                        TextSpan(text: ' ${notification.message}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Thời gian tạo thông báo
                  Text(
                    timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // Hiển thị chấm nhỏ nếu thông báo chưa đọc
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
