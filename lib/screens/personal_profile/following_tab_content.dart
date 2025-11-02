import 'package:flutter/material.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/service/following_service.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/personalProfileScreen.dart';

// Widget cho tab "Following" trong profile
class FollowingTabContent extends StatefulWidget {
  final String userId; // ID profile đang xem
  final String? currentAuthUserId; // ID người đang đăng nhập
  final bool isMyProfile; // Xác định đây có phải profile của chính mình

  const FollowingTabContent({
    super.key,
    required this.userId,
    required this.currentAuthUserId,
    required this.isMyProfile,
  });

  @override
  State<FollowingTabContent> createState() => _FollowingTabContentState();
}

class _FollowingTabContentState extends State<FollowingTabContent> {
  final FollowingService _service =
      FollowingService(); // Service quản lý dữ liệu following
  bool _isLoading = true; // Trạng thái loading
  List<FollowingUser> _followingList = []; // Danh sách người đang follow

  @override
  void initState() {
    super.initState();
    _loadFollowing(); // Tải danh sách following khi widget khởi tạo
  }

  // --- HÀM XỬ LÝ DỮ LIỆU ---

  Future<void> _loadFollowing() async {
    setState(() => _isLoading = true);
    final data = await _service.fetchFollowing(
      userId: widget.userId,
      currentAuthUserId: widget.currentAuthUserId,
    );
    if (!mounted) return;
    setState(() {
      _followingList = data;
      _isLoading = false;
    });
  }

  // Logic follow/unfollow
  Future<void> _toggleFollow(FollowingUser user) async {
    if (widget.currentAuthUserId == null) {
      // Nếu chưa login, show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn cần đăng nhập để thực hiện hành động này!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final oldStatus = user.isFollowedByCurrentUser;
    setState(() {
      // Cập nhật UI trước
      user.isFollowedByCurrentUser = !oldStatus;
      if (widget.isMyProfile && oldStatus) {
        // Nếu đang xem profile của mình và unfollow, remove khỏi list
        _followingList.remove(user);
      }
    });

    try {
      // Gọi service cập nhật Firestore
      await _service.toggleFollow(
        currentUserId: widget.currentAuthUserId!,
        targetUserId: user.user.id,
        isCurrentlyFollowing: oldStatus,
      );
    } catch (_) {
      // Rollback nếu xảy ra lỗi
      setState(() {
        user.isFollowedByCurrentUser = oldStatus;
        if (widget.isMyProfile && oldStatus) _loadFollowing();
      });
    }
  }

  // --- BUILD WIDGET ---

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

  // --- WIDGET ITEM FOLLOWING ---

  Widget _buildFollowingItem(BuildContext context, FollowingUser item) {
    final avatarProvider = item.user.avatarUrl.startsWith('http')
        ? NetworkImage(item.user.avatarUrl)
        : const AssetImage('assets/images/default_avatar.png') as ImageProvider;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Avatar click vào chuyển profile
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PersonalProfileScreen(userId: item.user.id),
              ),
            ),
            child: CircleAvatar(radius: 25, backgroundImage: avatarProvider),
          ),
          const SizedBox(width: 12),
          // Tên và số follower
          Expanded(
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PersonalProfileScreen(userId: item.user.id),
                ),
              ),
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
          // Nút Follow / Unfollow
          _buildFollowButton(item),
        ],
      ),
    );
  }

  // --- WIDGET NÚT FOLLOW / UNFOLLOW ---

  Widget _buildFollowButton(FollowingUser item) {
    final isMyProfile = widget.isMyProfile;
    final currentUserId = widget.currentAuthUserId;

    if (isMyProfile) {
      // Chủ profile -> luôn hiển thị nút outlined "Hủy theo dõi"
      return _outlinedButton("Hủy theo dõi", Colors.white, Colors.orange, () {
        _toggleFollow(item);
      });
    }

    // Nếu item là chính user đang login -> ẩn nút
    if (item.user.id == currentUserId) return const SizedBox(width: 90);

    // Nếu đang follow -> hiển thị nút outlined
    return item.isFollowedByCurrentUser
        ? _outlinedButton("Hủy theo dõi", Colors.white, Colors.orange, () {
            _toggleFollow(item);
          })
        // Nếu chưa follow -> hiển thị nút filled màu cam
        : _filledButton("Follow", Colors.orange, Colors.white, () {
            _toggleFollow(item);
          });
  }

  // Nút outlined
  Widget _outlinedButton(
    String text,
    Color bgColor,
    Color borderColor,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: borderColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Nút filled
  Widget _filledButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
