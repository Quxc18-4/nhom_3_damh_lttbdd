import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';

/// Model đại diện cho người dùng mà một user đang theo dõi
class FollowingUser {
  final User user;
  final int followersCount; // Số lượng người theo dõi
  bool isFollowedByCurrentUser; // Trạng thái follow từ currentUser

  FollowingUser({
    required this.user,
    required this.followersCount,
    required this.isFollowedByCurrentUser,
  });
}

/// Service xử lý follow / following của user
class FollowingService {
  final _db = FirebaseFirestore.instance;

  /// 🔹 Lấy danh sách người mà userId đang theo dõi
  ///
  /// Nếu currentAuthUserId != null, đồng thời kiểm tra xem current user có follow họ hay không
  Future<List<FollowingUser>> fetchFollowing({
    required String userId,
    required String? currentAuthUserId,
  }) async {
    try {
      // 1️⃣ Lấy tất cả document trong subcollection 'following' của user
      final followingSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();

      if (followingSnapshot.docs.isEmpty) return [];

      List<FollowingUser> result = [];

      // 2️⃣ Duyệt từng user đang được follow
      for (var doc in followingSnapshot.docs) {
        final id = doc.id; // userId của người đang follow
        final userDoc = await _db.collection('users').doc(id).get();
        if (!userDoc.exists) continue;

        final user = User.fromDoc(userDoc);
        final data = userDoc.data() ?? {};
        final followersCount = data['followersCount'] ?? 0;

        // 3️⃣ Kiểm tra xem current user có follow họ không
        bool isFollowedByMe = false;
        if (currentAuthUserId != null && currentAuthUserId != id) {
          final checkFollow = await _db
              .collection('users')
              .doc(currentAuthUserId)
              .collection('following')
              .doc(id)
              .get();
          isFollowedByMe = checkFollow.exists;
        }

        // 4️⃣ Thêm vào kết quả
        result.add(
          FollowingUser(
            user: user,
            followersCount: followersCount,
            isFollowedByCurrentUser: isFollowedByMe,
          ),
        );
      }

      return result;
    } catch (e) {
      print("❌ Lỗi fetchFollowing: $e");
      return [];
    }
  }

  /// 🔹 Follow hoặc Unfollow một user
  ///
  /// Nếu isCurrentlyFollowing = true thì sẽ unfollow, ngược lại sẽ follow
  Future<void> toggleFollow({
    required String currentUserId,
    required String targetUserId,
    required bool isCurrentlyFollowing,
  }) async {
    // References đến các document cần thay đổi
    final authUserFollowingRef = _db
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);

    final targetUserFollowerRef = _db
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);

    final authUserDocRef = _db.collection('users').doc(currentUserId);
    final targetUserDocRef = _db.collection('users').doc(targetUserId);

    try {
      if (isCurrentlyFollowing) {
        // UNFOLLOW
        await authUserFollowingRef.delete();
        await targetUserFollowerRef.delete();

        await authUserDocRef.update({
          'followingCount': FieldValue.increment(-1),
        });
        await targetUserDocRef.update({
          'followersCount': FieldValue.increment(-1),
        });
      } else {
        // FOLLOW
        final timestamp = FieldValue.serverTimestamp();
        await authUserFollowingRef.set({
          'followedAt': timestamp,
          'userId': targetUserId,
        });
        await targetUserFollowerRef.set({
          'followedAt': timestamp,
          'userId': currentUserId,
        });

        await authUserDocRef.update({
          'followingCount': FieldValue.increment(1),
        });
        await targetUserDocRef.update({
          'followersCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print("❌ Lỗi toggleFollow: $e");
      rethrow; // Ném lỗi ra ngoài để UI handle rollback
    }
  }
}
