import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:nhom_3_damh_lttbdd/screens/add_checkins/checkinScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/explore_screen/services/explore_service.dart';
import 'package:nhom_3_damh_lttbdd/screens/explore_screen/services/notification_service.dart';
import 'package:nhom_3_damh_lttbdd/screens/explore_screen/widgets/explore/create_post_bottom_sheet.dart';
import 'package:nhom_3_damh_lttbdd/screens/explore_screen/widgets/explore/explore_header.dart';
import 'package:nhom_3_damh_lttbdd/screens/explore_screen/widgets/explore/post_list_view.dart';
import 'package:nhom_3_damh_lttbdd/screens/notification_screen/notification_screen.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/personalProfileScreen.dart';
import '/model/post_model.dart';

class ExploreScreen extends StatefulWidget {
  final String userId;

  // ignore: use_super_parameters
  const ExploreScreen({Key? key, required this.userId}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  // --- SERVICES ---
  final ExploreService _exploreService = ExploreService();
  final NotificationService _notificationService = NotificationService();

  // --- CONTROLLERS ---
  late TabController _tabController;

  // --- STATE VARIABLES ---
  List<Post> _allPosts = [];
  Set<String> _followingIds = {};
  bool _isLoading = true;

  String _userName = "Đang tải...";
  String _userAvatarUrl = "assets/images/default_avatar.png";
  bool _isUserDataLoading = true;

  bool get _isAuthenticated => auth.FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- DATA LOADING ---

  Future<void> _initializeData() async {
    // Load user data và following list
    await Future.wait([_fetchUserData(), _fetchFollowingList()]);

    // Load posts sau khi có following list
    await _fetchPosts();
  }

  Future<void> _fetchUserData() async {
    final userData = await _exploreService.fetchUserData(widget.userId);
    if (mounted) {
      setState(() {
        _userName = userData['name']!;
        _userAvatarUrl = userData['avatarUrl']!;
        _isUserDataLoading = false;
      });
    }
  }

  Future<void> _fetchFollowingList() async {
    if (!_isAuthenticated) return;

    final followingIds = await _exploreService.fetchFollowingList(
      widget.userId,
    );
    if (mounted) {
      setState(() {
        _followingIds = followingIds;
      });
    }
  }

  Future<void> _fetchPosts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await _exploreService.fetchAllPosts(widget.userId);
      if (mounted) {
        setState(() {
          _allPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi tải bài viết: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- NAVIGATION HANDLERS ---

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalProfileScreen(userId: widget.userId),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationScreen(userId: widget.userId),
      ),
    );
  }

  void _showCreatePostOptions() {
    if (!_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn cần đăng nhập để tạo bài viết!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    CreatePostBottomSheet.show(
      context,
      onBlogTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckinScreen(currentUserId: widget.userId),
          ),
        ).then((_) => _fetchPosts());
      },
      onCheckinTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckinScreen(currentUserId: widget.userId),
          ),
        ).then((_) => _fetchPosts());
      },
      onQuestionTap: () {
        Navigator.pop(context);
        // TODO: Navigate to Question screen
      },
    );
  }

  // --- NOTIFICATION WRAPPER ---

  Future<void> _createNotification({
    required String recipientId,
    required String senderId,
    required String reviewId,
    required String type,
    required String message,
  }) async {
    await _notificationService.createNotification(
      recipientId: recipientId,
      senderId: senderId,
      reviewId: reviewId,
      type: type,
      message: message,
    );
  }

  // --- BUILD UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: ExploreHeader(
              userName: _userName,
              userAvatarUrl: _userAvatarUrl,
              isUserDataLoading: _isUserDataLoading,
              tabController: _tabController,
              onAvatarTap: _navigateToProfile,
              onNotificationTap: _navigateToNotifications,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostList(isExploreTab: true),
                      _buildPostList(isExploreTab: false),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostOptions,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPostList({required bool isExploreTab}) {
    final filteredPosts = _exploreService.filterPosts(
      allPosts: _allPosts,
      isExploreTab: isExploreTab,
      userId: widget.userId,
      followingIds: _followingIds,
    );

    return PostListView(
      posts: filteredPosts,
      userId: widget.userId,
      onPostUpdated: _fetchPosts,
      createNotification: _createNotification,
      isExploreTab: isExploreTab,
    );
  }
}
