// File: screens/home/home_page.dart
// (Đổi tên file từ homePage.dart thành home_page.dart và đặt trong folder /home)

import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'dart:async';

// Import các màn hình điều hướng (cập nhật đường dẫn nếu cần)
import 'package:nhom_3_damh_lttbdd/screens/profileScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/exploreScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/journey_map/journeyMapScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/trip_planner/tripPlannerScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/save_screen/saved_screen.dart';
import 'package:nhom_3_damh_lttbdd/screens/bannerDetailScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/notificationScreen.dart';

// Import Model
import 'package:nhom_3_damh_lttbdd/model/activity.dart';
import 'package:nhom_3_damh_lttbdd/model/banner.dart';

// Import hằng số
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart';

// Import Service và Widget đã tách
import 'service/home_service.dart';
import 'widget/home_widgets.dart';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Service
  final HomeService _homeService = HomeService();

  // State: Navigation
  int _selectedIndex = 0;

  // State: Dữ liệu
  bool _isLoading = true;
  String _userNickname = '';
  List<List<Activity>> _dayActivitiesPreview = List.generate(3, (index) => []);
  DateTime _startDate = DateTime.now();
  List<BannerModel> _activeBanners = [];
  Set<String> _visitedProvinces = {};
  int _unreadNotificationCount = 0;

  // Stream
  StreamSubscription? _notificationSubscription;

  // Dữ liệu tĩnh
  final List<Map<String, dynamic>> _services = [
    {
      "title": "Tìm chuyến bay",
      "assetPath": 'assets/images/Frame 331.png',
      "bgColor": const Color(0xFFC5E1A5),
    },
    {
      "title": "Khách sạn/Điểm lưu trú",
      "assetPath": 'assets/images/Frame 332.png',
      "bgColor": const Color(0xFFFFE0B2),
    },
    {
      "title": "Tình trạng chuyến bay",
      "assetPath": 'assets/images/Frame 341.png',
      "bgColor": const Color(0xFFBBDEFB),
    },
    {
      "title": "Thông báo giá vé",
      "assetPath": 'assets/images/Frame 342.png',
      "bgColor": const Color(0xFFF8BBD0),
    },
    {
      "title": "Thuê xe",
      "assetPath": 'assets/images/Frame 334.png',
      "bgColor": const Color(0xFFB2EBF2),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // === TẢI DỮ LIỆU ===

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      // Tải song song các dữ liệu
      final results = await Future.wait([
        _homeService.fetchUserData(),
        _homeService.fetchTripStartDate(),
        _homeService.fetchActivityPreviews(),
        _homeService.fetchActiveBanners(),
        _homeService.fetchVisitedProvinces(widget.userId),
      ]);

      if (mounted) {
        setState(() {
          _userNickname = results[0] as String;
          _startDate = results[1] as DateTime;
          _dayActivitiesPreview = results[2] as List<List<Activity>>;
          _activeBanners = results[3] as List<BannerModel>;
          _visitedProvinces = results[4] as Set<String>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError("Không thể tải dữ liệu trang chủ: $e");
    }
  }

  void _setupNotificationListener() {
    _notificationSubscription = _homeService
        .getNotificationStream(widget.userId)
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() => _unreadNotificationCount = snapshot.docs.length);
            }
          },
          onError: (error) {
            print("Lỗi khi lắng nghe thông báo: $error");
          },
        );
  }

  // === HÀM ĐIỀU HƯỚNG & HELPER ===

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationScreen(userId: widget.userId),
      ),
    ).then((_) {
      // Re-setup listener (hoặc có thể setup lại trong init/resume)
    });
  }

  void _navigateToJourneyMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneyMapScreen(userId: widget.userId),
      ),
    ).then((_) => _loadAllData()); // Tải lại data khi quay về
  }

  void _navigateToTripPlanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TripPlannerScreen()),
    );
    // Tải lại preview lịch trình khi quay về
    final startDate = await _homeService.fetchTripStartDate();
    final previews = await _homeService.fetchActivityPreviews();
    setState(() {
      _startDate = startDate;
      _dayActivitiesPreview = previews;
    });
  }

  void _navigateToBannerDetail(BannerModel banner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BannerDetailScreen(banner: banner),
      ),
    );
  }

  // === CÁC WIDGET CHÍNH CỦA TAB ===

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          HomeHeader(
            userNickname: _userNickname,
            unreadCount: _unreadNotificationCount,
            onNotificationTap: _navigateToNotifications,
            searchController:
                TextEditingController(), // TODO: Quản lý state search
          ),

          // 2. Services
          ServiceSection(services: _services),

          // 3. Journey Map Preview
          JourneyMapPreview(
            isLoadingMap:
                false, // Không cần loading riêng vì đã có loading chung
            visitedCount: _visitedProvinces.length,
            totalCount: kAllProvinceIds.length,
            onTap: _navigateToJourneyMap,
          ),
          const SizedBox(height: 10),

          // 4. Trip Plan Preview
          TripPlanPreview(
            startDate: _startDate,
            dayActivitiesPreview: _dayActivitiesPreview,
            onNavigate: _navigateToTripPlanner,
          ),
          const SizedBox(height: 20),

          // 5. News Feed
          NewsFeedSection(activeBanners: _activeBanners),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBookingContent() => const Center(
    child: Text(
      'Đặt chỗ của tôi',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    ),
  );

  Widget _buildSavedContent() => SavedScreen(userId: widget.userId);

  Widget _buildExploreContent() => ExploreScreen(userId: widget.userId);

  Widget _buildProfileContent() => ProfileScreen(userId: widget.userId);

  Widget _getSelectedContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildExploreContent();
      case 2:
        return _buildBookingContent();
      case 3:
        return _buildSavedContent();
      case 4:
        return _buildProfileContent();
      default:
        return _buildHomeContent();
    }
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Travel Review App';
      case 1:
        return 'Khám phá';
      case 2:
        return 'Đặt chỗ của tôi';
      case 3:
        return 'Đã lưu';
      case 4:
        return 'Tài khoản';
      default:
        return 'Travel Review App';
    }
  }

  // === MAIN BUILD ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Ẩn AppBar vì Header tùy chỉnh đã bao gồm nó
      appBar: _selectedIndex == 0
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(45.0),
              child: AppBar(
                title: Text(
                  _getAppBarTitle(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
                // Thay đổi màu AppBar cho các tab khác
                backgroundColor: _selectedIndex == 2
                    ? Colors.orange[600]
                    : Colors.teal[700],
              ),
            ),
      body: _getSelectedContent(),
      bottomNavigationBar: ConvexAppBar(
        items: const [
          TabItem(icon: Icons.home_outlined, title: 'Trang chủ'),
          TabItem(icon: Icons.explore_outlined, title: 'Khám phá'),
          TabItem(icon: Icons.event_available, title: 'Đặt chỗ'),
          TabItem(icon: Icons.bookmark_outline, title: 'Đã lưu'),
          TabItem(icon: Icons.person_outline, title: 'Tài khoản'),
        ],
        initialActiveIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        style: TabStyle.react,
        backgroundColor: Colors.white,
        color: Colors.grey[600],
        activeColor: Colors.orange[600],
        height: 60,
        elevation: 8,
      ),
    );
  }
}
