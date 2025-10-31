import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ===================================================================
// 1. MODEL CLASSES
// ===================================================================

class User {
  final String id;
  final String name;
  final String avatarUrl;

  User({required this.id, required this.name, required this.avatarUrl});

  factory User.empty() => User(
    id: '',
    name: 'Đang tải...',
    avatarUrl: 'assets/images/default_avatar.png',
  );

  factory User.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return User(
      id: doc.id,
      name: data['name'] ?? data['fullName'] ?? 'Người dùng',
      avatarUrl: data['avatarUrl'] ?? 'assets/images/default_avatar.png',
    );
  }
}

class Post {
  final String id;
  final User author;
  final String authorId;
  final String title;
  final String content;
  final String timeAgo;
  final List<String> imageUrls;
  final List<String> tags;
  int likeCount;
  final int commentCount;
  bool isLikedByUser; // ✅ Thêm trạng thái like

  Post({
    required this.id,
    required this.author,
    required this.authorId,
    required this.title,
    required this.content,
    required this.timeAgo,
    required this.imageUrls,
    required this.tags,
    required this.likeCount,
    required this.commentCount,
    this.isLikedByUser = false,
  });

  factory Post.fromDoc(
    DocumentSnapshot doc,
    User postAuthor, {
    bool isLiked = false,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final Timestamp timestamp = data['createdAt'] ?? Timestamp.now();
    final DateTime postTime = timestamp.toDate();
    final String formattedTime = DateFormat(
      'dd/MM/yyyy, HH:mm',
    ).format(postTime);

    return Post(
      id: doc.id,
      author: postAuthor,
      authorId: data['userId'] ?? '',
      title: data['title'] ?? 'Không có tiêu đề',
      content: data['comment'] ?? '',
      timeAgo: formattedTime,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      tags: List<String>.from(data['hashtags'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      isLikedByUser: isLiked,
    );
  }
}
