import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/model/comment_model.dart';

/// Widget hiển thị từng comment
/// Bao gồm avatar, tên user, thời gian, nội dung và action like/reply
class CommentItem extends StatelessWidget {
  /// Dữ liệu comment
  final CommentModel comment;

  /// Callback khi nhấn like
  final VoidCallback onLike;

  /// Callback khi nhấn reply
  final VoidCallback onReply;

  const CommentItem({
    Key? key,
    required this.comment,
    required this.onLike,
    required this.onReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Định dạng thời gian hiển thị comment
    final timeFormat = DateFormat('HH:mm, dd/MM');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================
          // Avatar user
          // ==========================
          CircleAvatar(
            radius: 18,
            backgroundImage: comment.author.avatarUrl.startsWith('http')
                ? NetworkImage(comment.author.avatarUrl)
                : AssetImage(comment.author.avatarUrl) as ImageProvider,
          ),
          const SizedBox(width: 12),

          // ==========================
          // Nội dung comment
          // ==========================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Tên author + Thời gian
                Row(
                  children: [
                    Text(
                      comment.author.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeFormat.format(comment.commentedAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Nội dung comment
                Text(comment.content, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 8),

                // ==========================
                // Actions: Like + Reply
                // ==========================
                Row(
                  children: [
                    // Like button
                    InkWell(
                      onTap: onLike,
                      child: Row(
                        children: [
                          Text(
                            'Thích',
                            style: TextStyle(
                              color: comment.isLikedByUser
                                  ? Colors.red.shade700
                                  : Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          // Hiển thị số lượng like nếu > 0
                          if (comment.likeCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text(
                                '(${comment.likeCount})',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Reply button
                    InkWell(
                      onTap: onReply,
                      child: Text(
                        'Phản hồi',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
