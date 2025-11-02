import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/model/post_model.dart';

/// Service xử lý dữ liệu cho màn hình Explore / feed
class ExploreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache user để tránh fetch nhiều lần cùng 1 user
  final Map<String, User> _userCache = {};

  /// 🔹 Lấy danh sách các userId mà người dùng đang theo dõi
  Future<Set<String>> fetchFollowingList(String userId) async {
    try {
      final followingSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();

      // Trả về Set chứa các ID
      return followingSnapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      debugPrint("Lỗi tải danh sách Following: $e");
      return {};
    }
  }

  /// 🔹 Lấy thông tin cơ bản của user (name, avatar)
  Future<Map<String, String>> fetchUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'name': data['name'] ?? data['fullName'] ?? 'Người dùng',
          'avatarUrl': data['avatarUrl'] ?? 'assets/images/default_avatar.png',
        };
      }

      // Nếu không tìm thấy user
      return {
        'name': 'Không tìm thấy user',
        'avatarUrl': 'assets/images/default_avatar.png',
      };
    } catch (e) {
      debugPrint("Lỗi tải thông tin người dùng: $e");
      return {
        'name': 'Lỗi tải data',
        'avatarUrl': 'assets/images/default_avatar.png',
      };
    }
  }

  /// 🔹 Lấy tất cả các bài viết (reviews) theo thời gian giảm dần
  Future<List<Post>> fetchAllPosts(String currentUserId) async {
    try {
      QuerySnapshot reviewSnapshot = await _firestore
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      if (reviewSnapshot.docs.isEmpty) {
        return [];
      }

      List<Post> fetchedPosts = [];

      // Duyệt qua từng bài viết
      for (var reviewDoc in reviewSnapshot.docs) {
        final reviewData = reviewDoc.data() as Map<String, dynamic>? ?? {};
        final String authorId = reviewData['userId'] ?? '';

        // Fetch dữ liệu tác giả (author) với cache
        User postAuthor = await _fetchAuthor(authorId);

        // Kiểm tra xem currentUser đã like bài viết chưa
        bool isLiked = await _checkIfLiked(reviewDoc.id, currentUserId);

        // Thêm vào danh sách posts
        fetchedPosts.add(Post.fromDoc(reviewDoc, postAuthor, isLiked: isLiked));
      }

      return fetchedPosts;
    } catch (e) {
      debugPrint("Lỗi tải bài viết: $e");
      rethrow;
    }
  }

  /// 🔹 Lấy dữ liệu tác giả với cache để tránh fetch lại nhiều lần
  Future<User> _fetchAuthor(String authorId) async {
    if (authorId.isEmpty) {
      return User.empty();
    }

    // Nếu đã cache, trả về luôn
    if (_userCache.containsKey(authorId)) {
      return _userCache[authorId]!;
    }

    try {
      DocumentSnapshot authorDoc = await _firestore
          .collection('users')
          .doc(authorId)
          .get();

      if (authorDoc.exists) {
        final authorData = authorDoc.data() as Map<String, dynamic>;
        final displayName =
            authorData['name']?.toString().trim().isNotEmpty == true
            ? authorData['name']
            : (authorData['fullName'] ?? 'Người dùng ẩn danh');

        final author = User(
          id: authorDoc.id,
          name: displayName,
          avatarUrl:
              authorData['avatarUrl'] ?? 'assets/images/default_avatar.png',
        );

        _userCache[authorId] = author; // Lưu cache
        return author;
      } else {
        // Nếu user không tồn tại
        return User(
          id: authorId,
          name: 'Người dùng ẩn danh',
          avatarUrl: 'assets/images/default_avatar.png',
        );
      }
    } catch (e) {
      debugPrint("Lỗi fetch author $authorId: $e");
      return User(
        id: authorId,
        name: 'Lỗi tải User',
        avatarUrl: 'assets/images/default_avatar.png',
      );
    }
  }

  /// 🔹 Kiểm tra xem user hiện tại đã like bài viết chưa
  Future<bool> _checkIfLiked(String reviewId, String userId) async {
    try {
      final likeDoc = await _firestore
          .collection('reviews')
          .doc(reviewId)
          .collection('likes')
          .doc(userId)
          .get();
      return likeDoc.exists;
    } catch (e) {
      debugPrint("Lỗi kiểm tra like: $e");
      return false;
    }
  }

  /// 🔹 Lọc posts theo tab (Explore hoặc Following)
  List<Post> filterPosts({
    required List<Post> allPosts,
    required bool isExploreTab,
    required String userId,
    required Set<String> followingIds,
  }) {
    if (isExploreTab) {
      // Explore tab: show tất cả bài viết
      return allPosts;
    } else {
      // Following tab: chỉ show bài viết của các user đang follow + chính mình
      final Set<String> authorizedAuthors = followingIds.toSet()..add(userId);
      return allPosts
          .where((post) => authorizedAuthors.contains(post.authorId))
          .toList();
    }
  }
}
