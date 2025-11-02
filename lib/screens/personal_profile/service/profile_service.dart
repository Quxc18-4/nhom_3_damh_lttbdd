import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';

/// Service xử lý dữ liệu liên quan đến trang cá nhân (profile)
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  /// 🔹 Lấy dữ liệu người dùng theo `userId`
  /// Trả về `Map<String, dynamic>` hoặc null nếu không tìm thấy
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (!userDoc.exists) return null;
      return userDoc.data() as Map<String, dynamic>?;
    } catch (e) {
      print("❌ Lỗi getUserData: $e");
      return null;
    }
  }

  /// 🔹 Lấy danh sách bài viết (reviews) của người dùng
  /// - `postAuthor`: có thể truyền User để gán cho Post
  /// - Tính cả trạng thái liked bởi current user
  Future<List<Post>> getUserPosts(String userId, {User? postAuthor}) async {
    List<Post> posts = [];
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final currentAuthUserId = _auth.currentUser?.uid;

      for (var doc in snapshot.docs) {
        // Kiểm tra xem user hiện tại đã like post chưa
        bool isLiked = false;
        if (currentAuthUserId != null) {
          final likeDoc = await _firestore
              .collection('reviews')
              .doc(doc.id)
              .collection('likes')
              .doc(currentAuthUserId)
              .get();
          isLiked = likeDoc.exists;
        }
        posts.add(
          Post.fromDoc(doc, postAuthor ?? User.empty(), isLiked: isLiked),
        );
      }
    } catch (e) {
      print("❌ Lỗi getUserPosts: $e");
    }
    return posts;
  }

  /// 🔹 Kiểm tra xem `currentUserId` có đang follow `targetUserId` không
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      print("❌ Lỗi isFollowing: $e");
      return false;
    }
  }

  /// 🔹 Theo dõi hoặc bỏ theo dõi một user
  ///
  /// Trả về trạng thái follow mới (true nếu đang follow, false nếu unfollow)
  Future<bool> toggleFollow({
    required String currentUserId,
    required String targetUserId,
    required bool isFollowing,
  }) async {
    final myFollowing = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);

    final theirFollowers = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);

    final myDoc = _firestore.collection('users').doc(currentUserId);
    final theirDoc = _firestore.collection('users').doc(targetUserId);

    try {
      if (isFollowing) {
        // 🔹 Bỏ theo dõi
        await myFollowing.delete();
        await theirFollowers.delete();
        await myDoc.update({'followingCount': FieldValue.increment(-1)});
        await theirDoc.update({'followersCount': FieldValue.increment(-1)});
        return false;
      } else {
        // 🔹 Theo dõi
        final timestamp = FieldValue.serverTimestamp();
        await myFollowing.set({'followedAt': timestamp});
        await theirFollowers.set({'followedAt': timestamp});
        await myDoc.update({'followingCount': FieldValue.increment(1)});
        await theirDoc.update({'followersCount': FieldValue.increment(1)});
        return true;
      }
    } catch (e) {
      print("❌ Lỗi toggleFollow: $e");
      return isFollowing; // rollback trạng thái nếu lỗi
    }
  }
}
