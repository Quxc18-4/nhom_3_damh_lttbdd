// File: screens/comment/service/comment_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhom_3_damh_lttbdd/model/comment_model.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart'; // Cần cho User model

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, User> _userCache = {}; // Cache user

  /// Lấy Stream các comment của một bài review
  Stream<QuerySnapshot> getCommentsStream(String reviewId) {
    return _firestore
        .collection('reviews')
        .doc(reviewId)
        .collection('comments')
        .orderBy('commentedAt', descending: false)
        .snapshots();
  }

  /// Lấy và cache thông tin người dùng
  Future<User> fetchAndCacheUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final user = User(
          id: userId,
          name: data['name'] ?? data['fullName'] ?? 'Người dùng',
          avatarUrl: data['avatarUrl'] ?? 'assets/images/default_avatar.png',
        );
        _userCache[userId] = user;
        return user;
      }
    } catch (e) {
      print('⚠️ Lỗi khi lấy user $userId: $e');
    }
    // Trả về user rỗng nếu lỗi
    return User(
      id: userId,
      name: 'Người dùng ẩn',
      avatarUrl: 'assets/images/default_avatar.png',
    );
  }

  /// Map danh sách comment docs sang CommentModel (bao gồm fetch user và like status)
  Future<List<CommentModel>> mapCommentsWithUsers(
    List<QueryDocumentSnapshot> docs,
    String reviewId,
    String currentUserId,
  ) async {
    final bool isAuthenticated = currentUserId.isNotEmpty;

    try {
      final futures = docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String? ?? '';

        // 1. Kiểm tra Like
        bool isLiked = false;
        if (isAuthenticated) {
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

        // 2. Lấy thông tin Author
        User author = await fetchAndCacheUser(userId);

        // 3. Tạo Model
        return CommentModel.fromMap(data, doc.id, author, isLiked: isLiked);
      }).toList();

      return await Future.wait(futures);
    } catch (e, stack) {
      print('🔥 Lỗi khi map comment với user: $e');
      print(stack);
      rethrow;
    }
  }

  /// Gửi một comment mới (hoặc reply)
  Future<void> sendComment({
    required String reviewId,
    required String currentUserId,
    required String content,
    CommentModel? replyingToComment,
  }) async {
    try {
      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      final commentsRef = reviewRef.collection('comments');

      // 1. Chuẩn bị dữ liệu
      final Map<String, dynamic> commentData = {
        'userId': currentUserId,
        'content': content,
        'commentedAt': FieldValue.serverTimestamp(),
      };

      if (replyingToComment != null) {
        commentData['parentCommentId'] = replyingToComment.id;
      }

      // 2. Tạo comment
      await commentsRef.add(commentData);

      // 3. Cập nhật commentCount
      await reviewRef.update({'commentCount': FieldValue.increment(1)});
    } catch (e) {
      print('Error sending comment: $e');
      throw Exception('Lỗi gửi bình luận: $e');
    }
  }

  /// Thích hoặc bỏ thích một comment
  Future<void> toggleCommentLike({
    required String reviewId,
    required String commentId,
    required String currentUserId,
    required bool isCurrentlyLiked,
  }) async {
    final commentRef = _firestore
        .collection('reviews')
        .doc(reviewId)
        .collection('comments')
        .doc(commentId);
    final likeRef = commentRef.collection('likes').doc(currentUserId);

    try {
      if (isCurrentlyLiked) {
        await likeRef.delete();
        await commentRef.update({'likeCount': FieldValue.increment(-1)});
      } else {
        await likeRef.set({'createdAt': FieldValue.serverTimestamp()});
        await commentRef.update({'likeCount': FieldValue.increment(1)});
      }
    } catch (e) {
      print('Error toggle comment like: $e');
      throw Exception('Lỗi thích bình luận: $e');
    }
  }
}
