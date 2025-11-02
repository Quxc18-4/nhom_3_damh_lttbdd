import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/model/post_model.dart';
import '/model/comment_model.dart';

class PostDetailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache user data để tránh fetch lặp lại cùng user nhiều lần
  final Map<String, User> _userCache = {};

  // =============================
  // Fetch thông tin bài viết từ Firestore
  // =============================
  Future<Post?> fetchPost(String reviewId, String currentUserId) async {
    try {
      // Lấy document bài viết
      final reviewDoc = await _firestore
          .collection('reviews')
          .doc(reviewId)
          .get();

      if (!reviewDoc.exists) {
        return null;
      }

      final reviewData = reviewDoc.data() as Map<String, dynamic>;
      final String authorId = reviewData['userId'] ?? '';

      // Fetch thông tin tác giả, sử dụng cache nếu có
      User postAuthor = User.empty();
      if (authorId.isNotEmpty) {
        postAuthor = await fetchAndCacheUser(authorId);
      }

      // Kiểm tra xem người dùng hiện tại đã like bài viết chưa
      bool isLiked = false;
      if (currentUserId.isNotEmpty) {
        final likeDoc = await _firestore
            .collection('reviews')
            .doc(reviewId)
            .collection('likes')
            .doc(currentUserId)
            .get();
        isLiked = likeDoc.exists;
      }

      // Trả về Post object
      return Post.fromDoc(reviewDoc, postAuthor, isLiked: isLiked);
    } catch (e) {
      debugPrint('Error loading post: $e');
      rethrow;
    }
  }

  // =============================
  // Fetch và cache user
  // =============================
  Future<User> fetchAndCacheUser(String userId) async {
    // Nếu user đã cache, trả về luôn
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final user = User.fromDoc(userDoc);
        _userCache[userId] = user; // Lưu vào cache
        return user;
      }
    } catch (e) {
      debugPrint('Error fetching user $userId: $e');
    }

    // Trường hợp user bị xóa hoặc lỗi fetch
    return User(
      id: userId,
      name: 'Người dùng đã xóa',
      avatarUrl: 'assets/images/default_avatar.png',
    );
  }

  // =============================
  // Toggle like cho post
  // =============================
  Future<void> togglePostLike({
    required String reviewId,
    required String userId,
    required bool isCurrentlyLiked,
  }) async {
    final reviewRef = _firestore.collection('reviews').doc(reviewId);
    final likeRef = reviewRef.collection('likes').doc(userId);

    if (isCurrentlyLiked) {
      // Nếu đang like thì unlike
      await likeRef.delete();
      await reviewRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      // Nếu chưa like thì thêm like
      await likeRef.set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await reviewRef.update({'likeCount': FieldValue.increment(1)});
    }
  }

  // =============================
  // Gửi comment (hoặc reply comment)
  // =============================
  Future<void> sendComment({
    required String reviewId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    final reviewRef = _firestore.collection('reviews').doc(reviewId);
    final commentsRef = reviewRef.collection('comments');

    // Tạo data comment
    final Map<String, dynamic> commentData = {
      'userId': userId,
      'content': content,
      'commentedAt': FieldValue.serverTimestamp(),
    };

    if (parentCommentId != null) {
      commentData['parentCommentId'] = parentCommentId;
    }

    await commentsRef.add(commentData);

    // Cập nhật số lượng comment của bài viết
    await reviewRef.update({'commentCount': FieldValue.increment(1)});
  }

  // =============================
  // Toggle like cho comment
  // =============================
  Future<void> toggleCommentLike({
    required String reviewId,
    required String commentId,
    required String userId,
    required bool isCurrentlyLiked,
  }) async {
    final commentRef = _firestore
        .collection('reviews')
        .doc(reviewId)
        .collection('comments')
        .doc(commentId);

    final likeRef = commentRef.collection('likes').doc(userId);

    if (isCurrentlyLiked) {
      // Nếu đang like thì unlike
      await likeRef.delete();
      await commentRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      // Nếu chưa like thì thêm like
      await likeRef.set({'createdAt': FieldValue.serverTimestamp()});
      await commentRef.update({'likeCount': FieldValue.increment(1)});
    }
  }

  // =============================
  // Map comments với user data
  // =============================
  Future<List<CommentModel>> mapCommentsWithUsers(
    List<QueryDocumentSnapshot> docs,
    String reviewId,
    String currentUserId,
  ) async {
    final futures = docs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['userId'] as String? ?? '';

      // Kiểm tra xem user hiện tại đã like comment chưa
      bool isLiked = false;
      if (currentUserId.isNotEmpty) {
        final likeDoc = await _firestore
            .collection('reviews')
            .doc(reviewId)
            .collection('comments')
            .doc(doc.id)
            .collection('likes')
            .doc(currentUserId)
            .get();
        isLiked = likeDoc.exists;
      }

      // Fetch tác giả comment
      User author = User.empty();
      if (userId.isNotEmpty) {
        author = await fetchAndCacheUser(userId);
      }

      return CommentModel.fromMap(data, doc.id, author, isLiked: isLiked);
    }).toList();

    return await Future.wait(futures);
  }

  // =============================
  // Stream comments để hiển thị realtime
  // =============================
  Stream<QuerySnapshot> getCommentsStream(String reviewId) {
    return _firestore
        .collection('reviews')
        .doc(reviewId)
        .collection('comments')
        .orderBy('commentedAt', descending: false)
        .snapshots();
  }
}
