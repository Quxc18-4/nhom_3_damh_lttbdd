import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/model/post_model.dart';

class ExploreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache để tránh fetch lặp lại
  final Map<String, User> _userCache = {};

  /// Fetch danh sách Following IDs
  Future<Set<String>> fetchFollowingList(String userId) async {
    try {
      final followingSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();

      return followingSnapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      debugPrint("Lỗi tải danh sách Following: $e");
      return {};
    }
  }

  /// Fetch thông tin user
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

  /// Fetch tất cả posts
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

      for (var reviewDoc in reviewSnapshot.docs) {
        final reviewData = reviewDoc.data() as Map<String, dynamic>? ?? {};
        final String authorId = reviewData['userId'] ?? '';

        // Fetch author data
        User postAuthor = await _fetchAuthor(authorId);

        // Check if liked
        bool isLiked = await _checkIfLiked(reviewDoc.id, currentUserId);

        fetchedPosts.add(Post.fromDoc(reviewDoc, postAuthor, isLiked: isLiked));
      }

      return fetchedPosts;
    } catch (e) {
      debugPrint("Lỗi tải bài viết: $e");
      rethrow;
    }
  }

  /// Fetch author với cache
  Future<User> _fetchAuthor(String authorId) async {
    if (authorId.isEmpty) {
      return User.empty();
    }

    // Check cache
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

        _userCache[authorId] = author;
        return author;
      } else {
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

  /// Check if post is liked by user
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

  /// Lọc posts theo tab
  List<Post> filterPosts({
    required List<Post> allPosts,
    required bool isExploreTab,
    required String userId,
    required Set<String> followingIds,
  }) {
    if (isExploreTab) {
      return allPosts;
    } else {
      final Set<String> authorizedAuthors = followingIds.toSet()..add(userId);
      return allPosts
          .where((post) => authorizedAuthors.contains(post.authorId))
          .toList();
    }
  }
}
