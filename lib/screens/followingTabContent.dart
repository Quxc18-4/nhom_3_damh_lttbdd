import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart'; // Import User model
import 'package:nhom_3_damh_lttbdd/screens/personalProfileScreen.dart'; // Import PersonalProfileScreen

// Model để lưu trữ thông tin user đang follow
class FollowingUser {
  final User user;
  final int followersCount;
  bool isFollowedByCurrentUser; // Trạng thái này (A theo dõi C)

  FollowingUser({
    required this.user,
    required this.followersCount,
    required this.isFollowedByCurrentUser,
  });
}

class FollowingTabContent extends StatefulWidget {
  final String userId; // ID của profile đang xem
  final String? currentAuthUserId; // ID của user đang đăng nhập
  final bool isMyProfile;

  const FollowingTabContent({
    Key? key,
    required this.userId,
    required this.currentAuthUserId,
    required this.isMyProfile,
  }) : super(key: key);

  @override
  State<FollowingTabContent> createState() => _FollowingTabContentState();
}

class _FollowingTabContentState extends State<FollowingTabContent> {
  List<FollowingUser> _followingList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowing();
  }

  Future<void> _fetchFollowing() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Lấy danh sách ID_USER mà profile này đang following
      final followingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('following')
          .get();

      if (followingSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _followingList = [];
          });
        }
        return;
      }

      final List<String> followingIds = followingSnapshot.docs
          .map((doc) => doc.id)
          .toList();

      List<FollowingUser> tempList = [];

      // 2. Với mỗi ID, lấy thông tin user chi tiết
      for (String id in followingIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .get();

        if (userDoc.exists) {
          final User user = User.fromDoc(userDoc);
          final data = userDoc.data() as Map<String, dynamic>? ?? {};
          final int followers = data['followersCount'] ?? 0;

          // 3. Kiểm tra xem user ĐANG ĐĂNG NHẬP có follow người này (user) không
          bool isFollowedByMe = false;
          if (widget.currentAuthUserId != null &&
              widget.currentAuthUserId != id) {
            final followDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.currentAuthUserId)
                .collection('following')
                .doc(id)
                .get();
            isFollowedByMe = followDoc.exists;
          }

          tempList.add(
            FollowingUser(
              user: user,
              followersCount: followers,
              isFollowedByCurrentUser: isFollowedByMe,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _followingList = tempList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print("Lỗi fetch following: $e");
    }
  }

  // Logic follow/unfollow cho các item trong danh sách
  Future<void> _toggleFollow(
    String targetUserId,
    bool isCurrentlyFollowing,
  ) async {
    if (widget.currentAuthUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn cần đăng nhập để thực hiện hành động này!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Cập nhật UI trước
    setState(() {
      final user = _followingList.firstWhere((u) => u.user.id == targetUserId);
      user.isFollowedByCurrentUser = !isCurrentlyFollowing;
      // Nếu là profile của mình, xóa khỏi danh sách khi unfollow
      if (widget.isMyProfile && isCurrentlyFollowing) {
        _followingList.removeWhere((u) => u.user.id == targetUserId);
      }
    });

    // Cập nhật Firestore
    final authUserFollowingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentAuthUserId)
        .collection('following')
        .doc(targetUserId);

    final targetUserFollowerRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(widget.currentAuthUserId);

    final authUserDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentAuthUserId);
    final targetUserDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId);

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
          'userId': widget.currentAuthUserId!,
        });
        await authUserDocRef.update({
          'followingCount': FieldValue.increment(1),
        });
        await targetUserDocRef.update({
          'followersCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      // Rollback UI nếu lỗi
      setState(() {
        final user = _followingList.firstWhere(
          (u) => u.user.id == targetUserId,
        );
        user.isFollowedByCurrentUser = isCurrentlyFollowing;
        // Thêm lại nếu bị xóa
        if (widget.isMyProfile && isCurrentlyFollowing) {
          _fetchFollowing(); // Tải lại cho chắc
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_followingList.isEmpty) {
      return const Center(
        child: Text(
          "Chưa theo dõi ai.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _followingList.length,
      itemBuilder: (context, index) {
        final item = _followingList[index];
        return _buildFollowingItem(context, item);
      },
    );
  }

  Widget _buildFollowingItem(BuildContext context, FollowingUser item) {
    ImageProvider _getAvatarProvider() {
      if (item.user.avatarUrl.startsWith('http')) {
        return NetworkImage(item.user.avatarUrl);
      }
      // Giả sử ảnh local
      return const AssetImage('assets/images/default_avatar.png');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Avatar
          InkWell(
            onTap: () {
              // Điều hướng đến trang profile của người đó
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PersonalProfileScreen(userId: item.user.id),
                ),
              );
            },
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[200],
              backgroundImage: _getAvatarProvider(),
            ),
          ),
          const SizedBox(width: 12),

          // Tên và Vai trò
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PersonalProfileScreen(userId: item.user.id),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${item.followersCount} người theo dõi",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Nút Follow/Unfollow
          _buildFollowButton(item),
        ],
      ),
    );
  }

  Widget _buildFollowButton(FollowingUser item) {
    // Nếu là xem profile của chính mình (tab "Following" của tôi)
    if (widget.isMyProfile) {
      return ElevatedButton(
        onPressed: () => _toggleFollow(item.user.id, true), // Luôn là unfollow
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // Nền trắng
          foregroundColor: Colors.orange, // Chữ cam
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.orange[400]!), // Viền cam
          ),
        ),
        child: const Text(
          'Hủy theo dõi',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    // Nếu xem profile người khác:
    // 1. Không hiển thị nút nếu đó là chính mình
    if (item.user.id == widget.currentAuthUserId) {
      return const SizedBox(width: 90); // Giữ layout
    }

    // 2. Nút "Hủy theo dõi" (nếu user đang login follow người này)
    if (item.isFollowedByCurrentUser) {
      return ElevatedButton(
        onPressed: () => _toggleFollow(item.user.id, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.orange,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.orange[400]!),
          ),
        ),
        child: const Text(
          'Hủy theo dõi',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    // 3. Nút "Follow" (nếu user đang login chưa follow người này)
    return ElevatedButton(
      onPressed: () => _toggleFollow(item.user.id, false),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        'Follow',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
