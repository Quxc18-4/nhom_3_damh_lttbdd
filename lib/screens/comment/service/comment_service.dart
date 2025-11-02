// File: screens/comment/service/comment_service.dart

import 'package:flutter/material.dart'; // Thư viện chính Flutter (dùng cho BuildContext nếu cần)
import 'package:cloud_firestore/cloud_firestore.dart'; // Kết nối Firestore
import 'package:nhom_3_damh_lttbdd/model/comment_model.dart'; // Model cho bình luận
import 'package:nhom_3_damh_lttbdd/model/post_model.dart'; // Cần cho User model (trong post_model.dart)

class CommentService { // Service xử lý bình luận
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Khởi tạo Firestore
  final Map<String, User> _userCache = {}; // Cache thông tin người dùng để tránh gọi dư thừa

  /// Lấy Stream các comment của một bài review
  Stream<QuerySnapshot> getCommentsStream(String reviewId) { // Trả về stream các comment theo thời gian
    return _firestore
        .collection('reviews') // Collection reviews
        .doc(reviewId) // Document review cụ thể
        .collection('comments') // Sub-collection comments
        .orderBy('commentedAt', descending: false) // Sắp xếp theo thời gian tăng dần
        .snapshots(); // Stream cập nhật real-time
  }

  /// Lấy và cache thông tin người dùng
  Future<User> fetchAndCacheUser(String userId) async { // Lấy user từ Firestore, cache để tái sử dụng
    if (_userCache.containsKey(userId)) { // Nếu đã cache
      return _userCache[userId]!; // Trả về từ cache
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get(); // Gọi Firestore
      if (userDoc.exists && userDoc.data() != null) { // Nếu document tồn tại
        final data = userDoc.data()!; // Lấy dữ liệu
        final user = User( // Tạo model User
          id: userId,
          name: data['name'] ?? data['fullName'] ?? 'Người dùng', // Ưu tiên name, rồi fullName, rồi mặc định
          avatarUrl: data['avatarUrl'] ?? 'assets/images/default_avatar.png', // Ảnh đại diện
        );
        _userCache[userId] = user; // Lưu vào cache
        return user; // Trả về
      }
    } catch (e) { // Bắt lỗi
      print('Lỗi khi lấy user $userId: $e'); // In lỗi
    }
    // Trả về user rỗng nếu lỗi
    return User( // User mặc định
      id: userId,
      name: 'Người dùng ẩn',
      avatarUrl: 'assets/images/default_avatar.png',
    );
  }

  /// Map danh sách comment docs sang CommentModel (bao gồm fetch user và like status)
  Future<List<CommentModel>> mapCommentsWithUsers( // Chuyển đổi list document → list model
    List<QueryDocumentSnapshot> docs, // Danh sách document comment
    String reviewId, // ID bài review
    String currentUserId, // ID người dùng hiện tại
  ) async {
    final bool isAuthenticated = currentUserId.isNotEmpty; // Kiểm tra đã đăng nhập chưa

    try {
      final futures = docs.map((doc) async { // Duyệt từng document
        final data = doc.data() as Map<String, dynamic>; // Lấy dữ liệu
        final userId = data['userId'] as String? ?? ''; // ID người bình luận

        // 1. Kiểm tra Like
        bool isLiked = false; // Mặc định chưa thích
        if (isAuthenticated) { // Nếu đã đăng nhập
          final likeDoc = await _firestore // Kiểm tra trong sub-collection likes
              .collection('reviews')
              .doc(reviewId)
              .collection('comments')
              .doc(doc.id)
              .collection('likes')
              .doc(currentUserId)
              .get();
          isLiked = likeDoc.exists; // Có document → đã thích
        }

        // 2. Lấy thông tin Author
        User author = await fetchAndCacheUser(userId); // Lấy + cache user

        // 3. Tạo Model
        return CommentModel.fromMap(data, doc.id, author, isLiked: isLiked); // Tạo model
      }).toList();

      return await Future.wait(futures); // Chờ tất cả hoàn thành
    } catch (e, stack) { // Bắt lỗi
      print('Lỗi khi map comment với user: $e'); // In lỗi
      print(stack); // In stack trace
      rethrow; // Ném lại lỗi
    }
  }

  /// Gửi một comment mới (hoặc reply)
  Future<void> sendComment({ // Gửi bình luận
    required String reviewId, // ID bài review
    required String currentUserId, // ID người gửi
    required String content, // Nội dung
    CommentModel? replyingToComment, // Bình luận cha (nếu là reply)
  }) async {
    try {
      final reviewRef = _firestore.collection('reviews').doc(reviewId); // Ref bài review
      final commentsRef = reviewRef.collection('comments'); // Ref collection comments

      // 1. Chuẩn bị dữ liệu
      final Map<String, dynamic> commentData = { // Dữ liệu comment
        'userId': currentUserId,
        'content': content,
        'commentedAt': FieldValue.serverTimestamp(), // Thời gian server
      };

      if (replyingToComment != null) { // Nếu là reply
        commentData['parentCommentId'] = replyingToComment.id; // Gán ID comment cha
      }

      // 2. Tạo comment
      await commentsRef.add(commentData); // Thêm vào Firestore

      // 3. Cập nhật commentCount
      await reviewRef.update({'commentCount': FieldValue.increment(1)}); // Tăng đếm
    } catch (e) {
      print('Error sending comment: $e'); // In lỗi
      throw Exception('Lỗi gửi bình luận: $e'); // Ném lỗi
    }
  }

  /// Thích hoặc bỏ thích một comment
  Future<void> toggleCommentLike({ // Thích/bỏ thích
    required String reviewId, // ID bài review
    required String commentId, // ID comment
    required String currentUserId, // ID người dùng
    required bool isCurrentlyLiked, // Trạng thái hiện tại
  }) async {
    final commentRef = _firestore // Ref comment
        .collection('reviews')
        .doc(reviewId)
        .collection('comments')
        .doc(commentId);
    final likeRef = commentRef.collection('likes').doc(currentUserId); // Ref like

    try {
      if (isCurrentlyLiked) { // Nếu đang thích → bỏ thích
        await likeRef.delete(); // Xóa like
        await commentRef.update({'likeCount': FieldValue.increment(-1)}); // Giảm đếm
      } else { // Nếu chưa thích → thích
        await likeRef.set({'createdAt': FieldValue.serverTimestamp()}); // Tạo like
        await commentRef.update({'likeCount': FieldValue.increment(1)}); // Tăng đếm
      }
    } catch (e) {
      print('Error toggle comment like: $e'); // In lỗi
      throw Exception('Lỗi thích bình luận: $e'); // Ném lỗi
    }
  }
}