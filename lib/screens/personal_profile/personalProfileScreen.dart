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

class PersonalProfileScreen extends StatefulWidget {
  final String userId;
  const PersonalProfileScreen({super.key, required this.userId});

  @override
  State<PersonalProfileScreen> createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends State<PersonalProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileService _profileService = ProfileService(); // ✅ Dùng service

  User _currentUser = User.empty();
  Map<String, dynamic>? _rawUserData;
  List<Post> _myPosts = [];

  bool _isLoading = true;
  bool _isMyProfile = false;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  int _followersCount = 0;
  int _followingCount = 0;
  String? _currentAuthUserId;

  // ignore: unused_element
  bool get _isAuthenticated => auth.FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfileData();
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
    _currentAuthUserId = auth.FirebaseAuth.instance.currentUser?.uid;
    _isMyProfile = (_currentAuthUserId == widget.userId);

    try {
      // 1️⃣ Lấy thông tin user
      final userData = await _profileService.getUserData(widget.userId);
      if (userData != null) {
        _rawUserData = userData;
        _currentUser = User.fromMap(userData, id: widget.userId);
        _followersCount = userData['followersCount'] ?? 0;
        _followingCount = userData['followingCount'] ?? 0;
      }

      // 2️⃣ Lấy bài viết
      _myPosts = await _profileService.getUserPosts(
        widget.userId,
        postAuthor: _currentUser,
      );

      // 3️⃣ Kiểm tra follow status nếu không phải hồ sơ của mình
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
        _followersCount += newStatus ? 1 : -1;
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
          SliverPersistentHeader(
            delegate: SliverTabHeader(_tabController),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTimeline(),
            IntroductionTabContent(
              userData: _rawUserData,
              userPosts: _myPosts,
              isMyProfile: _isMyProfile,
              userId: widget.userId,
            ),
            AlbumTabContent(userId: widget.userId),
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
              _loadProfileData, // Gọi lại toàn bộ dữ liệu khi cập nhật
        );
      },
    );
  }
}
