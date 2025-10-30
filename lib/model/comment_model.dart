import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart'; // Import User model

class CommentModel {
  final String id;
  final String userId;
  final String content;
  final DateTime commentedAt;
  final User author;
  final String? parentCommentId; // ✅ Mới: Dùng cho Reply
  final int likeCount; // ✅ Mới
  bool isLikedByUser; // ✅ Mới

  CommentModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.commentedAt,
    required this.author,
    this.parentCommentId,
    this.likeCount = 0,
    this.isLikedByUser = false,
  });

  /// Factory constructor để ánh xạ từ Map dữ liệu Firestore.
  factory CommentModel.fromMap(Map<String, dynamic> data, String commentId, User author, {bool isLiked = false}) {
    final Timestamp timestamp = data['commentedAt'] ?? Timestamp.now();

    return CommentModel(
      id: commentId,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      commentedAt: timestamp.toDate(),
      author: author,
      parentCommentId: data['parentCommentId'],
      likeCount: data['likeCount'] ?? 0,
      isLikedByUser: isLiked,
    );
  }
}
