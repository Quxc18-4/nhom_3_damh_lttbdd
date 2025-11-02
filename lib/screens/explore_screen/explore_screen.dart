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
  final String userId; // ID của user hiện tại

  const ExploreScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  // --- SERVICES ---
  final ExploreService _exploreService =
      ExploreService(); // Service xử lý dữ liệu bài viết
  final NotificationService _notificationService =
      NotificationService(); // Service tạo thông báo

  // --- CONTROLLERS ---
  late TabController _tabController; // TabController cho TabBar

  // --- STATE VARIABLES ---
  List<Post> _allPosts = []; // Danh sách tất cả bài viết
  Set<String> _followingIds = {}; // Danh sách user đang follow
  bool _isLoading = true; // Loading khi fetch posts

  String _userName = "Đang tải..."; // Tên user hiển thị trên header
  String _userAvatarUrl = "assets/images/default_avatar.png"; // Avatar user
  bool _isUserDataLoading = true; // Loading state khi fetch user data

  bool get _isAuthenticated => auth.FirebaseAuth.instance.currentUser != null;
  // Kiểm tra user đã đăng nhập hay chưa

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // Khởi tạo tab controller với 2 tab
    _initializeData(); // Load dữ liệu khi mở màn hình
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose controller khi screen bị huỷ
    super.dispose();
  }

  // --- DATA LOADING ---
  /// Hàm tổng hợp load dữ liệu ban đầu
  Future<void> _initializeData() async {
    // Load user data và following list song song
    await Future.wait([_fetchUserData(), _fetchFollowingList()]);

    // Sau khi có following list, load posts
    await _fetchPosts();
  }

  /// Lấy dữ liệu user hiện tại
  Future<void> _fetchUserData() async {
    final userData = await _exploreService.fetchUserData(widget.userId);
    if (mounted) {
      setState(() {
        _userName = userData['name']!;
        _userAvatarUrl = userData['avatarUrl']!;
        _isUserDataLoading = false; // Đã tải xong dữ liệu user
      });
    }
  }

  /// Lấy danh sách user đang follow
  Future<void> _fetchFollowingList() async {
    if (!_isAuthenticated) return; // Nếu chưa login thì bỏ qua

    final followingIds = await _exploreService.fetchFollowingList(
      widget.userId,
    );
    if (mounted) {
      setState(() {
        _followingIds = followingIds; // Cập nhật danh sách following
      });
    }
  }

  /// Lấy tất cả bài viết từ Firestore
  Future<void> _fetchPosts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true; // Hiển thị loading
    });

    try {
      final posts = await _exploreService.fetchAllPosts(widget.userId);
      if (mounted) {
        setState(() {
          _allPosts = posts;
          _isLoading = false; // Hoàn tất loading
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Hiển thị lỗi nếu không tải được bài viết
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
  /// Navigate đến profile của user hiện tại
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalProfileScreen(userId: widget.userId),
      ),
    );
  }

  /// Navigate đến màn hình thông báo
  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationScreen(userId: widget.userId),
      ),
    );
  }

  /// Hiển thị bottom sheet chọn loại bài viết muốn tạo
  void _showCreatePostOptions() {
    if (!_isAuthenticated) {
      // Nếu chưa login → thông báo
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
        ).then((_) => _fetchPosts()); // Reload posts sau khi tạo
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
  /// Gói gọn hàm tạo notification
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
              onAvatarTap: _navigateToProfile, // Click avatar → profile
              onNotificationTap:
                  _navigateToNotifications, // Click bell → notifications
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orange,
                    ), // Loading spinner
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostList(isExploreTab: true), // Tab Khám phá
                      _buildPostList(isExploreTab: false), // Tab Dành cho bạn
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostOptions, // Click FAB → tạo bài viết
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Build danh sách bài viết theo tab
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
      onPostUpdated: _fetchPosts, // Callback khi post thay đổi → reload
      createNotification: _createNotification, // Callback tạo notification
      isExploreTab: isExploreTab,
    );
  }
}
