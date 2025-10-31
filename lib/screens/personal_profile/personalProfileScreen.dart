import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';
// Lưu ý: Đảm bảo các đường dẫn import này là chính xác trong dự án của bạn
import 'package:nhom_3_damh_lttbdd/screens/albumTabContent.dart';
import 'package:nhom_3_damh_lttbdd/screens/introductionTabContent.dart';
import 'package:nhom_3_damh_lttbdd/screens/followingTabContent.dart';

// 🧩 Các widget con đã tách sẵn
import 'widget/profile_header.dart';
import 'widget/sliver_tab_header.dart';
import 'widget/timeline_post_card.dart';

class PersonalProfileScreen extends StatefulWidget {
  final String userId;

  const PersonalProfileScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<PersonalProfileScreen> createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends State<PersonalProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User _currentUser = User.empty();
  // ✅ SỬA LỖI 1: Thêm biến để lưu dữ liệu thô (raw user data) cho IntroductionTabContent
  Map<String, dynamic>? _rawUserData;

  List<Post> _myPosts = [];
  bool _isLoading = true;

  bool _isMyProfile = false;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  int _followersCount = 0;
  int _followingCount = 0;
  String? _currentAuthUserId;

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
  // 🔹 FETCH PROFILE DATA
  // ===============================================================
  Future<void> _loadProfileData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    _currentAuthUserId = auth.FirebaseAuth.instance.currentUser?.uid;
    _isMyProfile = (_currentAuthUserId == widget.userId);

    try {
      // 1️⃣ Lấy dữ liệu user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        _currentUser = User.fromDoc(userDoc);
        final data = userDoc.data() as Map<String, dynamic>? ?? {};

        // ✅ SỬA LỖI 2: Lưu dữ liệu thô (Map) vào biến state mới
        _rawUserData = data;

        int followers = data['followersCount'] ?? 0;
        int following = data['followingCount'] ?? 0;

        setState(() {
          _followersCount = followers;
          _followingCount = following;
        });
      }

      // 2️⃣ Lấy bài viết
      await _fetchMyPosts();

      // 3️⃣ Kiểm tra follow status nếu không phải hồ sơ của mình
      if (!_isMyProfile) await _fetchFollowStatus();
    } catch (e) {
      print("❌ Lỗi tải dữ liệu Profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMyPosts() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<Post> posts = [];
      final postAuthor = _currentUser.id.isNotEmpty
          ? _currentUser
          : User.empty();

      for (var doc in snapshot.docs) {
        bool isLiked = false;
        if (_currentAuthUserId != null) {
          final likeDoc = await FirebaseFirestore.instance
              .collection('reviews')
              .doc(doc.id)
              .collection('likes')
              .doc(_currentAuthUserId)
              .get();
          isLiked = likeDoc.exists;
        }
        posts.add(Post.fromDoc(doc, postAuthor, isLiked: isLiked));
      }

      if (mounted) setState(() => _myPosts = posts);
    } catch (e) {
      print("❌ Lỗi tải bài viết: $e");
    }
  }

  Future<void> _fetchFollowStatus() async {
    if (!_isAuthenticated || _currentAuthUserId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentAuthUserId)
          .collection('following')
          .doc(widget.userId)
          .get();
      if (mounted) setState(() => _isFollowing = doc.exists);
    } catch (e) {
      print("❌ Lỗi tải follow status: $e");
    }
  }

  // ===============================================================
  // 🔹 FOLLOW/UNFOLLOW
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

    final myFollowing = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentAuthUserId)
        .collection('following')
        .doc(widget.userId);

    final theirFollowers = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .doc(_currentAuthUserId);

    final myDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentAuthUserId);
    final theirDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId);

    try {
      if (_isFollowing) {
        await myFollowing.delete();
        await theirFollowers.delete();
        await myDoc.update({'followingCount': FieldValue.increment(-1)});
        await theirDoc.update({'followersCount': FieldValue.increment(-1)});
        setState(() {
          _isFollowing = false;
          _followersCount--;
        });
      } else {
        final timestamp = FieldValue.serverTimestamp();
        await myFollowing.set({'followedAt': timestamp});
        await theirFollowers.set({'followedAt': timestamp});
        await myDoc.update({'followingCount': FieldValue.increment(1)});
        await theirDoc.update({'followersCount': FieldValue.increment(1)});
        setState(() {
          _isFollowing = true;
          _followersCount++;
        });
      }
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
              // Giữ lại tham số nếu có trong ProfileHeader của bạn
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

            // ✅ SỬA LỖI 3: Truyền biến _rawUserData đã sửa lỗi 'undefined_method'
            IntroductionTabContent(
              userData: _rawUserData,
              userPosts: _myPosts,
              isMyProfile: _isMyProfile,
              userId: widget.userId,
            ),

            AlbumTabContent(userId: widget.userId),

            // ✅ SỬA LỖI 4: Truyền các tham số bắt buộc cho FollowingTabContent
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
  // 🔹 TIMELINE TAB
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
          onPostUpdated: _fetchMyPosts,
        );
      },
    );
  }
}
