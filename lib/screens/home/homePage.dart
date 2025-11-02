// File: screens/home/home_page.dart
// (Đổi tên file từ homePage.dart thành home_page.dart và đặt trong folder /home)

import 'package:flutter/material.dart'; // Thư viện chính của Flutter
import 'package:convex_bottom_bar/convex_bottom_bar.dart'; // Thanh bottom bar dạng cong
import 'package:nhom_3_damh_lttbdd/screens/notification_screen/notification_screen.dart'; // Màn hình thông báo
import 'dart:async'; // Dùng cho StreamSubscription

// Import các màn hình điều hướng (cập nhật đường dẫn nếu cần)
import 'package:nhom_3_damh_lttbdd/screens/user_setting/profileScreen.dart'; // Màn hình hồ sơ
import 'package:nhom_3_damh_lttbdd/screens/explore_screen/explore_screen.dart'; // Màn hình khám phá
import 'package:nhom_3_damh_lttbdd/screens/journey_map/journeyMapScreen.dart'; // Màn hình bản đồ hành trình
import 'package:nhom_3_damh_lttbdd/screens/trip_planner/tripPlannerScreen.dart'; // Màn hình lập kế hoạch
import 'package:nhom_3_damh_lttbdd/screens/save_screen/saved_screen.dart'; // Màn hình đã lưu
import 'package:nhom_3_damh_lttbdd/screens/bannerDetailScreen.dart'; // Màn hình chi tiết banner

// Import Model
import 'package:nhom_3_damh_lttbdd/model/activity.dart'; // Model hoạt động (time, title, icon)
import 'package:nhom_3_damh_lttbdd/model/banner.dart'; // Model banner (title, content, imageUrl, endDate)

// Import hằng số
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart'; // Danh sách tỉnh (kAllProvinceIds)

// Import Service và Widget đã tách
import 'service/home_service.dart'; // Service xử lý dữ liệu Home
import 'widget/home_widgets.dart'; // Các widget con của Home

class HomePage extends StatefulWidget { // Trang chính, có trạng thái
  final String userId; // ID người dùng (từ Firebase Auth)
  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState(); // Tạo state
}

class _HomePageState extends State<HomePage> { // State của HomePage
  // Service
  final HomeService _homeService = HomeService(); // Khởi tạo service xử lý dữ liệu

  // State: Navigation
  int _selectedIndex = 0; // Chỉ số tab hiện tại (0: Home, 1: Khám phá, ...)

  // State: Dữ liệu
  bool _isLoading = true; // Đang tải toàn bộ dữ liệu
  String _userNickname = ''; // Tên người dùng
  List<List<Activity>> _dayActivitiesPreview = List.generate(3, (index) => []); // 3 ngày preview
  DateTime _startDate = DateTime.now(); // Ngày bắt đầu hành trình
  List<BannerModel> _activeBanners = []; // Danh sách banner đang hoạt động
  Set<String> _visitedProvinces = {}; // Tỉnh đã check-in
  int _unreadNotificationCount = 0; // Số thông báo chưa đọc

  // Stream
  StreamSubscription? _notificationSubscription; // Theo dõi realtime thông báo

  // Dữ liệu tĩnh
  final List<Map<String, dynamic>> _services = [ // Danh sách dịch vụ hiển thị
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
  void initState() { // Khởi tạo khi widget được tạo
    super.initState();
    _loadAllData(); // Tải toàn bộ dữ liệu
    _setupNotificationListener(); // Bắt đầu lắng nghe thông báo
  }

  @override
  void dispose() { // Dọn dẹp khi widget bị hủy
    _notificationSubscription?.cancel(); // Hủy stream
    super.dispose();
  }

  // === TẢI DỮ LIỆU ===

  Future<void> _loadAllData() async { // Tải tất cả dữ liệu khi mở trang
    setState(() => _isLoading = true); // Bật loading
    try {
      // Tải song song các dữ liệu
      final results = await Future.wait([ // Chờ tất cả hoàn thành
        _homeService.fetchUserData(), // Tên người dùng
        _homeService.fetchTripStartDate(), // Ngày bắt đầu
        _homeService.fetchActivityPreviews(), // 3 ngày preview
        _homeService.fetchActiveBanners(), // Banner
        _homeService.fetchVisitedProvinces(widget.userId), // Tỉnh đã đi
      ]);

      if (mounted) { // Kiểm tra widget còn tồn tại
        setState(() {
          _userNickname = results[0] as String;
          _startDate = results[1] as DateTime;
          _dayActivitiesPreview = results[2] as List<List<Activity>>;
          _activeBanners = results[3] as List<BannerModel>;
          _visitedProvinces = results[4] as Set<String>;
          _isLoading = false; // Tắt loading
        });
      }
    } catch (e) { // Bắt lỗi
      if (mounted) setState(() => _isLoading = false);
      _showError("Không thể tải dữ liệu trang chủ: $e"); // Hiển thị lỗi
    }
  }

  void _setupNotificationListener() { // Lắng nghe thông báo realtime
    _notificationSubscription = _homeService
        .getNotificationStream(widget.userId) // Lấy stream
        .listen(
          (snapshot) { // Khi có thay đổi
            if (mounted) {
              setState(() => _unreadNotificationCount = snapshot.docs.length); // Cập nhật số lượng
            }
          },
          onError: (error) { // Lỗi stream
            print("Lỗi khi lắng nghe thông báo: $error");
          },
        );
  }

  // === HÀM ĐIỀU HƯỚNG & HELPER ===

  void _showError(String message) { // Hiển thị lỗi bằng SnackBar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToNotifications() { // Mở màn hình thông báo
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationScreen(userId: widget.userId),
      ),
    ).then((_) {
      // Re-setup listener (hoặc có thể setup lại trong init/resume)
    });
  }

  void _navigateToJourneyMap() { // Mở bản đồ hành trình
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneyMapScreen(userId: widget.userId),
      ),
    ).then((_) => _loadAllData()); // Tải lại data khi quay về
  }

  void _navigateToTripPlanner() async { // Mở lập kế hoạch
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

  void _navigateToBannerDetail(BannerModel banner) { // Mở chi tiết banner
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BannerDetailScreen(banner: banner),
      ),
    );
  }

  // === CÁC WIDGET CHÍNH CỦA TAB ===

  Widget _buildHomeContent() { // Nội dung tab Trang chủ
    if (_isLoading) { // Nếu đang tải
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView( // Có thể cuộn
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

  Widget _buildBookingContent() => const Center( // Tab Đặt chỗ
    child: Text(
      'Đặt chỗ của tôi',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    ),
  );

  Widget _buildSavedContent() => SavedScreen(userId: widget.userId); // Tab Đã lưu

  Widget _buildExploreContent() => ExploreScreen(userId: widget.userId); // Tab Khám phá

  Widget _buildProfileContent() => ProfileScreen(userId: widget.userId); // Tab Tài khoản

  Widget _getSelectedContent() { // Chọn nội dung theo tab
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

  String _getAppBarTitle() { // Tiêu đề AppBar theo tab
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
  Widget build(BuildContext context) { // Xây dựng giao diện chính
    return Scaffold(
      backgroundColor: Colors.grey[100], // Màu nền
      // Ẩn AppBar vì Header tùy chỉnh đã bao gồm nó
      appBar: _selectedIndex == 0 // Chỉ hiện AppBar ở các tab khác
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
      body: _getSelectedContent(), // Nội dung chính
      bottomNavigationBar: ConvexAppBar( // Thanh điều hướng dưới
        items: const [
          TabItem(icon: Icons.home_outlined, title: 'Trang chủ'),
          TabItem(icon: Icons.explore_outlined, title: 'Khám phá'),
          TabItem(icon: Icons.event_available, title: 'Đặt chỗ'),
          TabItem(icon: Icons.bookmark_outline, title: 'Đã lưu'),
          TabItem(icon: Icons.person_outline, title: 'Tài khoản'),
        ],
        initialActiveIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index), // Chuyển tab
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