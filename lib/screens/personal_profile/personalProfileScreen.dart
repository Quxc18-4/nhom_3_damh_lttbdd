import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/album_tab_content.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/following_tab_content.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/introduction_tab.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/service/profile_service.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/widgets/personal_profile/profile_header.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/widgets/personal_profile/sliver_tab_header.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/widgets/personal_profile/timeline_post_card.dart';

/// Màn hình profile cá nhân
class PersonalProfileScreen extends StatefulWidget {
  final String userId; // ID của user muốn xem profile

  const PersonalProfileScreen({super.key, required this.userId});

  @override
  State<PersonalProfileScreen> createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends State<PersonalProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ProfileService _profileService =
      ProfileService(); // Service xử lý dữ liệu

  // Thông tin user
  User _currentUser = User.empty();
  Map<String, dynamic>? _rawUserData;
  List<Post> _myPosts = [];

  bool _isLoading = true; // Trạng thái loading toàn bộ profile
  bool _isMyProfile = false; // Profile có phải của chính mình không
  bool _isFollowing = false; // Trạng thái follow user
  bool _isFollowLoading = false; // Loading khi follow/unfollow

  int _followersCount = 0;
  int _followingCount = 0;
  String? _currentAuthUserId;

  bool get _isAuthenticated => auth.FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfileData(); // Load dữ liệu khi mở màn hình
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ===============================================================
  // 🔹 LOAD DỮ LIỆU PROFILE
  // ===============================================================
  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    // Lấy user đang đăng nhập
    _currentAuthUserId = auth.FirebaseAuth.instance.currentUser?.uid;
    _isMyProfile = (_currentAuthUserId == widget.userId);

    try {
      // 1️⃣ Lấy dữ liệu user từ Firestore
      final userData = await _profileService.getUserData(widget.userId);
      if (userData != null) {
        _rawUserData = userData;
        _currentUser = User.fromMap(userData, id: widget.userId);
        _followersCount = userData['followersCount'] ?? 0;
        _followingCount = userData['followingCount'] ?? 0;
      }

      // 2️⃣ Lấy bài viết của user
      _myPosts = await _profileService.getUserPosts(
        widget.userId,
        postAuthor: _currentUser,
      );

      // 3️⃣ Kiểm tra trạng thái follow nếu không phải hồ sơ của mình
      if (!_isMyProfile && _currentAuthUserId != null) {
        _isFollowing = await _profileService.isFollowing(
          _currentAuthUserId!,
          widget.userId,
        );
      }
    } catch (e) {
      print("❌ Lỗi load profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===============================================================
  // 🔹 FOLLOW / UNFOLLOW
  // ===============================================================
  Future<void> _toggleFollow() async {
    if (_currentAuthUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn cần đăng nhập để thực hiện hành động này!"),
        ),
      );
      return;
    }

    if (_isFollowLoading || _isMyProfile) return;

    setState(() => _isFollowLoading = true);

    try {
      final newStatus = await _profileService.toggleFollow(
        currentUserId: _currentAuthUserId!,
        targetUserId: widget.userId,
        isFollowing: _isFollowing,
      );

      setState(() {
        _isFollowing = newStatus;
        _followersCount += newStatus ? 1 : -1; // Update số follower
      });
    } catch (e) {
      print("❌ Lỗi toggle follow: $e");
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  // ===============================================================
  // 🔹 BUILD UI
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Header profile: Avatar, stats, follow button
          SliverToBoxAdapter(
            child: ProfileHeader(
              user: _currentUser,
              isMyProfile: _isMyProfile,
              isFollowing: _isFollowing,
              isLoadingFollow: _isFollowLoading,
              followersCount: _followersCount,
              followingCount: _followingCount,
              postCount: _myPosts.length,
              onFollowToggle: _toggleFollow,
              currentUserId: widget.userId,
            ),
          ),
          // Tab bar
          SliverPersistentHeader(
            delegate: SliverTabHeader(_tabController),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTimeline(), // Timeline post
            IntroductionTabContent(
              userData: _rawUserData,
              userPosts: _myPosts,
              isMyProfile: _isMyProfile,
              userId: widget.userId,
            ),
            AlbumTabContent(userId: widget.userId), // Album
            FollowingTabContent(
              userId: widget.userId,
              currentAuthUserId: _currentAuthUserId,
              isMyProfile: _isMyProfile,
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // 🔹 DANH SÁCH BÀI VIẾT
  // ===============================================================
  Widget _buildTimeline() {
    if (_myPosts.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có bài viết nào.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _myPosts.length,
      itemBuilder: (context, i) {
        return TimelinePostCard(
          post: _myPosts[i],
          currentAuthUserId: _currentAuthUserId,
          onPostUpdated:
              _loadProfileData, // Load lại toàn bộ dữ liệu khi post được cập nhật
        );
      },
    );
  }
}
