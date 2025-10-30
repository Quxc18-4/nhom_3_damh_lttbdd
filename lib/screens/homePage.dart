import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
// Giả định các import này vẫn cần thiết
import 'package:nhom_3_damh_lttbdd/screens/profileScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/exploreScreen.dart';
import 'tripPlannerScreen.dart'; // Đảm bảo bạn có file này và class TravelPlanPage
import 'package:nhom_3_damh_lttbdd/screens/saveScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// THÊM: Import Model và Service để truy cập dữ liệu local
import 'package:nhom_3_damh_lttbdd/model/activity.dart'; 
import 'package:nhom_3_damh_lttbdd/services/local_plan_service.dart'; 

// Giả định các đường dẫn assets (GIỮ NGUYÊN)
const String _ASSET_AVATAR = 'assets/images/image 8.png';
const String _ASSET_HOTEL = 'assets/images/Frame 332.png';
const String _ASSET_FLIGHT_GREEN = 'assets/images/Frame 331.png';
const String _ASSET_FLIGHT_BLUE_ALERT = 'assets/images/Frame 341.png';
const String _ASSET_NOTI_BELL = 'assets/images/Frame 342.png'; // Placeholder cho Thông báo giá vé
const String _ASSET_CAR_RENTAL = 'assets/images/Frame 334.png'; // Placeholder cho Thuê xe

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  // Service để tải dữ liệu
  final LocalPlanService _localPlanService = LocalPlanService();

  // ĐÃ SỬA: Dữ liệu Preview 3 ngày đầu
  List<List<Activity>> _dayActivitiesPreview = List.generate(3, (index) => []); 
  DateTime _startDate = DateTime.now(); // Thêm biến ngày bắt đầu
  String _userNickname = ''; // Thêm biến để lưu nickname
  bool _isLoadingUserData = true; // Để kiểm soát trạng thái loading

  // Dữ liệu mẫu cho các dịch vụ (GIỮ NGUYÊN)
  final List<Map<String, dynamic>> _services = [
    {"title": "Tìm chuyến bay", "assetPath": _ASSET_FLIGHT_GREEN, "bgColor": const Color(0xFFC5E1A5)}, 
    {"title": "Khách sạn/Điểm lưu trú", "assetPath": _ASSET_HOTEL, "bgColor": const Color(0xFFFFE0B2)}, 
    {"title": "Tình trạng chuyến bay", "assetPath": _ASSET_FLIGHT_BLUE_ALERT, "bgColor": const Color(0xFFBBDEFB)}, 
    {"title": "Thông báo giá vé", "assetPath": _ASSET_NOTI_BELL, "bgColor": const Color(0xFFF8BBD0)}, 
    {"title": "Thuê xe", "assetPath": _ASSET_CAR_RENTAL, "bgColor": const Color(0xFFB2EBF2)},
  ];

  // Dữ liệu mẫu cho Tin tức (GIỮ NGUYÊN)
  final List<Map<String, dynamic>> _newsFeed = [
    {
      "tag": "#Đà Lạt",
      "content": "Đà Lạt chào đón tôi bằng không khí se lạnh và những con đèo",
      "image": "https://images.unsplash.com/photo-1596765798402-421b16c4c0b5?fit=crop&w=400&q=80",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStartDate(); // Tải ngày bắt đầu
    _loadDayActivitiesPreview(); // Tải dữ liệu 3 ngày khi khởi tạo
    _loadUserData(); // Tải dữ liệu người dùng
  }

  // Tải ngày bắt đầu từ Local Storage
  Future<void> _loadStartDate() async {
    final savedDate = await _localPlanService.loadStartDate();
    if (savedDate != null) {
      setState(() {
        _startDate = savedDate;
      });
    }
  }

  // Tải dữ liệu người dùng từ Firebase
  Future<void> _loadUserData() async {
    setState(() => _isLoadingUserData = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userNickname = userDoc.data()?['name'] ?? 'Mydei'; // Lấy nickname từ Firestore
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

  // CẬP NHẬT: Hàm tải hoạt động cho 3 ngày đầu tiên từ Local Storage
  Future<void> _loadDayActivitiesPreview() async {
    final allDays = await _localPlanService.loadAllDays();
    
    // Tạo list tạm thời để chứa 3 ngày đầu (hoặc ít hơn nếu tổng số ngày < 3)
    List<List<Activity>> tempActivities = List.generate(3, (index) => []);

    if (allDays.isNotEmpty) {
      for (int i = 0; i < 3; i++) {
        if (i < allDays.length) {
          // Lấy hoạt động của ngày thứ i
          tempActivities[i] = allDays[i].activities;
        }
      }
      
      setState(() {
        _dayActivitiesPreview = tempActivities; 
      });
    } else {
      setState(() {
        // Đặt lại về 3 list rỗng nếu chưa có data
        _dayActivitiesPreview = List.generate(3, (index) => []);
      });
    }
  }

  // CẬP NHẬT: Widget Activity Item để nhận Activity Model
  Widget _buildActivityItem(Activity activity) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // 💙 Xanh nhạt bên trong
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF64B5F6), // 💙 Xanh đậm hơn để làm viền
          width: 1.5,
        ),
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
          const Icon(Icons.access_time, size: 16, color: Color(0xFF1976D2)), // Dùng màu cố định
          const SizedBox(width: 8),
          Text(
            activity.time, // <--- Dùng Model
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1565C0), // Dùng màu cố định
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity.title, // <--- Dùng Model
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.15), // <--- Dùng Model
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                activity.icon, // <--- Dùng Model (IconData)
                size: 18,
                color: activity.color, // <--- Dùng Model
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelPlanPreview() {
  // Tính ngày cho 3 ngày đầu dựa trên _startDate
  final day1 = _startDate;
  final day2 = _startDate.add(const Duration(days: 1));
  final day3 = _startDate.add(const Duration(days: 2));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Tiêu đề Travel Plan
      Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Travel Plan Đà Lạt của bạn',
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
                // Tải lại dữ liệu sau khi quay về
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
      const SizedBox(height: 6), // giảm khoảng cách cho sát hơn

      // Tabs
      // Tabs
      DefaultTabController(
        length: 3,
        initialIndex: 0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // --- Thanh tab trên ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: EdgeInsets.zero,
                  labelColor: Colors.blue.shade700,
                  unselectedLabelColor: Colors.teal.shade300,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  tabs: [
                    Tab(
                      child: Text(
                        'Day 1 - ${day1.day.toString().padLeft(2, '0')}/${day1.month.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Day 2 - ${day2.day.toString().padLeft(2, '0')}/${day2.month.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Day 3 - ${day3.day.toString().padLeft(2, '0')}/${day3.month.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Lịch / hoạt động bên dưới ---
              Container(
                height: 180,
                decoration: const BoxDecoration(
                color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
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
            ],
          ),
        ),
      ),
    ],
  );
}

  // 1. Widget Header tùy chỉnh
  Widget _buildCustomHeader() {
    // Lấy thời gian hiện tại để chào đúng buổi
    String greeting;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Chào buổi sáng';
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều';
    } else {
      greeting = 'Chào buổi tối';
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFE0B2), // 🌟 vàng nhạt
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row( // Dòng ngày tháng + icon
            children: [
              const Icon(Icons.calendar_month, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              // Cập nhật ngày tháng hiện tại (22/10/2025, Thứ Tư)
              Text('Thứ Tư, 22 Tháng 10 2025', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_outlined, color: Colors.black),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row( // Avatar + chào buổi
            children: [
              ClipOval(
                child: Image.asset(
                  _ASSET_AVATAR,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$greeting, ${_userNickname.isNotEmpty ? _userNickname : "Mydei"}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField( // Search Bar
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView( // Suggestion Chips
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSuggestionChip('Hotel Đà Lạt', const Color(0xFFFFCC80)),
                _buildSuggestionChip('Thuê xe tại Huế', const Color(0xFFB3E5FC)),
                _buildSuggestionChip('Vé máy bay giá rẻ', const Color(0xFFFFAB91)),
                _buildSuggestionChip('Tour Đà Lạt', const Color(0xFFC5E1A5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm _buildSuggestionChip (giả định bạn đã định nghĩa)
  Widget _buildSuggestionChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
    );
  }
  
  // Widget Dịch vụ (sử dụng asset placeholder)
  Widget _buildServiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Text('Dịch vụ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  ? Image.asset(assetPath, width: 50, height: 50, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red))
                  : const Icon(Icons.error, color: Colors.red);

              final Color bgColor = (service["bgColor"] as Color?) ?? Colors.grey.shade200;

              return Container(
                width: 70,
                margin: const EdgeInsets.only(right: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 25, backgroundColor: bgColor, child: serviceIcon),
                    const SizedBox(height: 4),
                    Text(service["title"].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12), maxLines: 2),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget Travel Map
  Widget _buildTravelMapSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Travel Map của bạn',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Đã khám phá 8/64 tỉnh thành tại Việt Nam',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Widget News Feed
  Widget _buildNewsFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('News Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
        // Item đầu tiên của News Feed
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(_newsFeed[0]["image"].toString(), width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey.shade300)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _newsFeed[0]["tag"].toString(),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_newsFeed[0]["content"].toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // TỔNG HỢP NỘI DUNG HOME PAGE
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

  // GIỮ NGUYÊN CÁC HÀM CÒN LẠI
  Widget _buildExploreContent() => const Center(
    child: Text('Trang Khám phá', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
  );

  Widget _buildBookingContent() => const Center(
    child: Text('Đặt chỗ của tôi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
  );

  Widget _buildSavedContent() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bookmark_outline, size: 80, color: Colors.grey),
        SizedBox(height: 16),
        Text('Đã lưu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _getSelectedContent() {
    switch (_selectedIndex) {
      case 0: return _buildHomeContent();
      case 1: return ExploreScreen(userId: widget.userId);
      case 2: return _buildBookingContent();
      case 3: return SavedScreen(userId: widget.userId);
      case 4: return ProfileScreen(userId: widget.userId);
      default: return _buildHomeContent();
    }
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0: return 'Travel Review App';
      case 1: return 'Khám phá';
      case 2: return 'Đặt chỗ của tôi';
      case 3: return 'Đã lưu';
      case 4: return 'Tài khoản';
      default: return 'Travel Review App';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(45.0),
        child: AppBar(
          title: Text(_getAppBarTitle(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          backgroundColor: _selectedIndex == 2 ? Colors.orange[600] : Colors.teal,
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