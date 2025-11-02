import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:nhom_3_damh_lttbdd/screens/profileScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/exploreScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/journey_map/service/journey_map_service.dart';
import 'tripPlannerScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/save_screen/saved_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Import Model và Screens mới/cần thiết
import 'package:nhom_3_damh_lttbdd/model/activity.dart';
import 'package:nhom_3_damh_lttbdd/services/local_plan_service.dart';
import 'package:nhom_3_damh_lttbdd/model/banner.dart';
import 'package:nhom_3_damh_lttbdd/screens/journey_map/journeyMapScreen.dart';
// Dùng để lấy tổng số tỉnh (kAllProvinceIds)
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart';
import 'bannerDetailScreen.dart';
import 'notificationScreen.dart';

// Giả định các đường dẫn assets (GIỮ NGUYÊN)
const String _ASSET_AVATAR = 'assets/images/image 8.png';
const String _ASSET_HOTEL = 'assets/images/Frame 332.png';
const String _ASSET_FLIGHT_GREEN = 'assets/images/Frame 331.png';
const String _ASSET_FLIGHT_BLUE_ALERT = 'assets/images/Frame 341.png';
const String _ASSET_NOTI_BELL = 'assets/images/Frame 342.png';
const String _ASSET_CAR_RENTAL = 'assets/images/Frame 334.png';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final LocalPlanService _localPlanService = LocalPlanService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<List<Activity>> _dayActivitiesPreview = List.generate(3, (index) => []);
  DateTime _startDate = DateTime.now();
  String _userNickname = '';
  bool _isLoadingUserData = true;
  List<BannerModel> _activeBanners = [];

  final JourneyMapService _mapService = JourneyMapService();
  Set<String> _visitedProvinces = {};
  bool _isLoadingMap = true;

  // [MỚI] Biến và Subscription cho Thông báo
  int _unreadNotificationCount = 0;
  StreamSubscription? _notificationSubscription;

  final List<Map<String, dynamic>> _services = [
    {
      "title": "Tìm chuyến bay",
      "assetPath": _ASSET_FLIGHT_GREEN,
      "bgColor": const Color(0xFFC5E1A5),
    },
    {
      "title": "Khách sạn/Điểm lưu trú",
      "assetPath": _ASSET_HOTEL,
      "bgColor": const Color(0xFFFFE0B2),
    },
    {
      "title": "Tình trạng chuyến bay",
      "assetPath": _ASSET_FLIGHT_BLUE_ALERT,
      "bgColor": const Color(0xFFBBDEFB),
    },
    {
      "title": "Thông báo giá vé",
      "assetPath": _ASSET_NOTI_BELL,
      "bgColor": const Color(0xFFF8BBD0),
    },
    {
      "title": "Thuê xe",
      "assetPath": _ASSET_CAR_RENTAL,
      "bgColor": const Color(0xFFB2EBF2),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStartDate();
    _loadDayActivitiesPreview();
    _loadUserData();
    _loadActiveBanners();
    _setupNotificationListener();
    _loadVisitedProvinces(); // Giữ lại hàm này
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // [MỚI] Thiết lập Listener cho thông báo chưa đọc
  void _setupNotificationListener() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _notificationSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                _unreadNotificationCount = snapshot.docs.length;
              });
            }
          },
          onError: (error) {
            print("Lỗi khi lắng nghe thông báo: $error");
          },
        );
  }

  // [MỚI] Hàm điều hướng đến màn hình thông báo
  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationScreen(userId: widget.userId),
      ),
    ).then((_) {
      _setupNotificationListener();
    });
  }

  // --- LOAD DATA FUNCTIONS ---

  Future<void> _loadStartDate() async {
    final savedDate = await _localPlanService.loadStartDate();
    if (savedDate != null) {
      setState(() {
        _startDate = savedDate;
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUserData = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            _userNickname = userDoc.data()?['name'] ?? 'Mydei';
            _isLoadingUserData = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _loadDayActivitiesPreview() async {
    final allDays = await _localPlanService.loadAllDays();

    List<List<Activity>> tempActivities = List.generate(3, (index) => []);

    if (allDays.isNotEmpty) {
      for (int i = 0; i < 3; i++) {
        if (i < allDays.length) {
          tempActivities[i] = allDays[i].activities;
        }
      }

      setState(() {
        _dayActivitiesPreview = tempActivities;
      });
    } else {
      setState(() {
        _dayActivitiesPreview = List.generate(3, (index) => []);
      });
    }
  }

  Future<void> _loadActiveBanners() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('banners')
          .where('endDate', isGreaterThan: now)
          .orderBy('endDate', descending: false)
          .limit(5)
          .get();

      setState(() {
        _activeBanners = snapshot.docs
            .map((doc) => BannerModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print("Lỗi khi tải banners: $e");
    }
  }

  Future<void> _loadVisitedProvinces() async {
    if (!mounted) return;
    setState(() => _isLoadingMap = true);
    try {
      final provinces = await _mapService.loadHighlightedProvinces(
        widget.userId,
      );
      if (mounted) {
        setState(() {
          _visitedProvinces = provinces;
        });
      }
    } catch (e) {
      print("Lỗi tải dữ liệu bản đồ (Home): $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingMap = false);
      }
    }
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildActivityItem(Activity activity) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF64B5F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 16, color: Color(0xFF1976D2)),
          const SizedBox(width: 8),
          Text(
            activity.time,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity.title,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(activity.icon, size: 18, color: activity.color),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET NÀY ĐÃ ĐƯỢC MERGE
  Widget _buildTravelPlanPreview() {
    final day1 = _startDate;
    final day2 = _startDate.add(const Duration(days: 1));
    final day3 = _startDate.add(const Duration(days: 2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch trình du lịch của bạn',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TravelPlanPage(),
                    ),
                  );
                  _loadStartDate();
                  _loadDayActivitiesPreview();
                },
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '${day1.day.toString().padLeft(2, '0')}/${day1.month.toString().padLeft(2, '0')}/${day1.year} - '
            '${day3.day.toString().padLeft(2, '0')}/${day3.month.toString().padLeft(2, '0')}/${day3.year}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        const SizedBox(height: 6),

        // Tabs
        DefaultTabController(
          length: 3,
          initialIndex: 0,
          child: Column(
            children: [
              // --- Thanh tab trên ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30), // Bo tròn nhẹ hơn
                  ),
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: EdgeInsets.zero,
                    labelColor: Colors.blue.shade700,
                    unselectedLabelColor: Colors.grey.shade800,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    tabs: [
                      Tab(
                        child: Text(
                          'Day 1 - ${day1.day.toString().padLeft(2, '0')}/${day1.month.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Day 2 - ${day2.day.toString().padLeft(2, '0')}/${day2.month.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Day 3 - ${day3.day.toString().padLeft(2, '0')}/${day3.month.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Lịch / hoạt động bên dưới ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: SizedBox(
                  height: 180,
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(3, (dayIndex) {
                      final activities = _dayActivitiesPreview[dayIndex];
                      if (activities.isEmpty) {
                        return Center(
                          child: Text(
                            'Chưa có hoạt động nào cho Day ${dayIndex + 1}',
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          return _buildActivityItem(activities[index]);
                        },
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ WIDGET JOURNEY MAP ĐÃ MERGE VÀ SỬ DỤNG LOGIC ĐỘNG
  Widget _buildTravelMapSection() {
    // 1. Lấy tổng số tỉnh
    int totalCount = kAllProvinceIds.length;

    return InkWell(
      onTap: () {
        // Điều hướng sang JourneyMapScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JourneyMapScreen(userId: widget.userId),
          ),
        ).then((_) {
          // Tải lại dữ liệu map khi quay về
          _loadVisitedProvinces();
        });
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Journey Map của bạn',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 4),

            // HIỂN THỊ TEXT ĐỘNG
            _isLoadingMap
                ? const Text(
                    'Đang tải dữ liệu bản đồ...',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  )
                : Text(
                    'Đã khám phá ${_visitedProvinces.length}/$totalCount tỉnh thành tại Việt Nam',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildServiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Text(
            'Dịch vụ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              final String? assetPath = service['assetPath'] as String?;

              final serviceIcon = (assetPath != null && assetPath.isNotEmpty)
                  ? Image.asset(
                      assetPath,
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error, color: Colors.red),
                    )
                  : const Icon(Icons.error, color: Colors.red);

              final Color bgColor =
                  (service["bgColor"] as Color?) ?? Colors.grey.shade200;

              return Container(
                width: 70,
                margin: const EdgeInsets.only(right: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: bgColor,
                      child: serviceIcon,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service["title"].toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewsFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tin Tức & Ưu Đãi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              GestureDetector(
                onTap: () {
                  // Hành động khi nhấn Xem thêm (nếu có màn hình danh sách banner)
                },
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        if (_activeBanners.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Text(
              'Hiện chưa có tin tức nào.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ..._activeBanners.map((banner) => _buildBannerItem(banner)).toList(),
      ],
    );
  }

  Widget _buildCustomHeader() {
    String greeting;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Chào buổi sáng';
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều';
    } else {
      greeting = 'Chào buổi tối';
    }

    final today = DateTime.now();
    // Đảm bảo locale 'vi_VN' đã được khởi tạo trong main.dart
    final dayOfWeek = DateFormat('EEEE', 'vi_VN').format(today);
    final formattedDate = DateFormat('dd MMMM yyyy', 'vi_VN').format(today);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFE0B2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                '${dayOfWeek}, ${formattedDate.replaceAll(',', '')}',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.qr_code_scanner_outlined,
                  color: Colors.black,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),

              // NÚT THÔNG BÁO VỚI HUY HIỆU
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.black,
                    ),
                    onPressed: _navigateToNotifications, // Điều hướng
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          _unreadNotificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  _ASSET_AVATAR,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$greeting, ${_userNickname.isNotEmpty ? _userNickname : "Mydei"}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSuggestionChip('Hotel Đà Lạt', const Color(0xFFFFCC80)),
                _buildSuggestionChip(
                  'Thuê xe tại Huế',
                  const Color(0xFFB3E5FC),
                ),
                _buildSuggestionChip(
                  'Vé máy bay giá rẻ',
                  const Color(0xFFFFAB91),
                ),
                _buildSuggestionChip('Tour Đà Lạt', const Color(0xFFC5E1A5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerItem(BannerModel banner) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BannerDetailScreen(banner: banner),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                banner.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hết hạn: ${DateFormat('dd/MM/yyyy').format(banner.endDate)}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomHeader(),
          _buildServiceSection(),
          _buildTravelMapSection(),
          const SizedBox(height: 10),
          _buildTravelPlanPreview(),
          const SizedBox(height: 20),
          _buildNewsFeedSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- NAVIGATION LOGIC ---

  Widget _buildBookingContent() => const Center(
    child: Text(
      'Đặt chỗ của tôi',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    ),
  );

  Widget _buildSavedContent() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bookmark_outline, size: 80, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'Đã lưu',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _getSelectedContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return ExploreScreen(userId: widget.userId);
      case 2:
        return _buildBookingContent();
      case 3:
        return SavedScreen(userId: widget.userId);
      case 4:
        return ProfileScreen(userId: widget.userId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(45.0),
        child: AppBar(
          title: Text(
            _getAppBarTitle(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          backgroundColor: _selectedIndex == 2
              ? Colors.orange[600]
              : Colors.teal,
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
