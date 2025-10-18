import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
// Giả định các import này vẫn cần thiết
import 'package:nhom_3_damh_lttbdd/screens/profileScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/exploreScreen.dart';
import 'tripPlannerScreen.dart'; // Đảm bảo bạn có file này và class TravelPlanPage
import 'package:nhom_3_damh_lttbdd/screens/saveScreen.dart';

// Giả định các đường dẫn assets
const String _ASSET_AVATAR = 'assets/images/image 8.png';
const String _ASSET_HOTEL = 'assets/images/Frame 332.png';
const String _ASSET_FLIGHT_GREEN = 'assets/images/Frame 331.png';
const String _ASSET_FLIGHT_BLUE_ALERT = 'assets/images/Frame 341.png';
const String _ASSET_NOTI_BELL = 'assets/images/Frame 342.png'; // Placeholder cho Thông báo giá vé
const String _ASSET_CAR_RENTAL = 'assets/images/Frame 334.png'; // Placeholder cho Thuê xe
class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  // Dữ liệu mẫu cho Lịch trình Đà Lạt
  final List<Map<String, dynamic>> _dalatActivities = [
    {"time": "4:30", "title": "Thức dậy", "iconAsset": Icons.wb_sunny_outlined, "iconColor": Colors.amber},
    {"time": "5:30", "title": "Săn bình minh/Săn mây", "iconAsset": Icons.cloud_outlined, "iconColor": Colors.blueGrey},
    {"time": "7:30", "title": "Ăn sáng", "iconAsset": Icons.restaurant, "iconColor": Colors.lightBlueAccent},
    {"time": "8:30", "title": "Cà phê/Chụp ảnh", "iconAsset": Icons.camera_alt_outlined, "iconColor": Colors.brown},
  ];

  // Dữ liệu mẫu cho các dịch vụ (sử dụng asset placeholder)
  final List<Map<String, dynamic>> _services = [
    // Tim chuyến bay (Green background)
    {"title": "Tìm chuyến bay", "assetPath": _ASSET_FLIGHT_GREEN, "bgColor": const Color(0xFFC5E1A5)}, 
    // Khách sạn (Orange background)
    {"title": "Khách sạn/Điểm lưu trú", "assetPath": _ASSET_HOTEL, "bgColor": const Color(0xFFFFE0B2)}, 
    // Tình trạng chuyến bay (Blue background + Red alert dot)
    {"title": "Tình trạng chuyến bay", "assetPath": _ASSET_FLIGHT_BLUE_ALERT, "bgColor": const Color(0xFFBBDEFB)}, 
    // Thông báo giá vé (Màu chuông, dùng Icon)
    {"title": "Thông báo giá vé", "assetPath": _ASSET_NOTI_BELL, "bgColor": const Color(0xFFF8BBD0)}, 
    // 5. Thuê xe (MỚI: Dùng ASSET_CAR_RENTAL)
    {"title": "Thuê xe", "assetPath": _ASSET_CAR_RENTAL, "bgColor": const Color(0xFFB2EBF2)},
  ];

  // Dữ liệu mẫu cho Tin tức
  final List<Map<String, dynamic>> _newsFeed = [
    {"tag": "#Đà Lạt", "content": "Đà Lạt chào đón tôi bằng không khí se lạnh và những con đèo", "image": "https://images.unsplash.com/photo-1596765798402-421b16c4c0b5?fit=crop&w=400&q=80"},
  ];

  // 4. Widget Activity Item trong Travel Plan Preview
  // 4. Widget Activity Item trong Travel Plan Preview
// 4. Widget Activity Item trong Travel Plan Preview - ĐÃ CHỈNH SỬA THEO ẢNH
Widget _buildActivityItem(Map<String, dynamic> activity) {
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
        Icon(Icons.access_time, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          activity["time"].toString(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            activity["title"].toString(),
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
            color: (activity["iconColor"] as Color).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              activity["iconAsset"] as IconData,
              size: 18,
              color: activity["iconColor"] as Color,
            ),
          ),
        ),
      ],
    ),
  );
}

  // 3. Widget Travel Plan Preview
  Widget _buildTravelPlanPreview() {
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TravelPlanPage()),
                  );
                },
                child: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('20/08/2025 - 22/08/2025', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        const SizedBox(height: 10),

        // Tabs
        DefaultTabController(
          length: 3,
          initialIndex: 0,
          child: Column(
            children: [
              Container(
                color: Colors.white, // Nền trắng cho TabBar
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: TabBar(
                  isScrollable: true,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: Colors.blue,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  tabs: [
                    Tab(child: Text('Day 1 - 20/08', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    Tab(child: Text('Day 2 - 21/08', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    Tab(child: Text('Day 3 - 22/08', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  ],
                ),
              ),
              
              // Danh sách hoạt động
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: SizedBox(
                  height: 180, // Chiều cao cố định
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Day 1
                      ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _dalatActivities.length,
                        itemBuilder: (context, index) {
                          return _buildActivityItem(_dalatActivities[index]);
                        },
                      ),
                      // Day 2 (Placeholder)
                      const Center(child: Text('Chưa có dữ liệu Day 2')),
                      // Day 3 (Placeholder)
                      const Center(child: Text('Chưa có dữ liệu Day 3')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 1. Widget Header tùy chỉnh
  Widget _buildCustomHeader() {
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
        // --- Dòng ngày tháng + icon ---
        Row(
          children: [
            const Icon(Icons.calendar_month, size: 20, color: Colors.black54),
            const SizedBox(width: 8),
            Text(
              'Thứ Bảy, 10 Tháng 5 2025',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
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

        // --- Avatar + chào buổi sáng ---
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
            const Text(
              'Chào buổi sáng, Mydei!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9800),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // --- Search Bar ---
        TextField(
          decoration: InputDecoration(
            hintText: 'Tìm kiếm...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.white, // nền trắng trong khung vàng
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // --- Suggestion Chips ---
        SingleChildScrollView(
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

Widget _buildSuggestionChip(String text, Color bgColor) {
  return Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );
}





  
  // Widget Dịch vụ (sử dụng asset placeholder) - ĐÃ FIX LỖI NULL
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
              const Text('Travel Map của bạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Đã khám phá 8/64 tỉnh thành tại Việt Nam', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
              const Text(
                'News Feed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
        // Item đầu tiên của News Feed
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Ảnh
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _newsFeed[0]["image"].toString(),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_newsFeed[0]["tag"].toString(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _newsFeed[0]["content"].toString(), 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
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

  Widget _buildExploreContent() => const Center(
    child: Text(
      'Trang Khám phá',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    ),
  );

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

  // 🧠 Hàm _buildAnimatedIcon đã được xóa vì không cần thiết nữa

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        // 👇 Đặt chiều cao bạn muốn ở đây. Chiều cao mặc định là 56.0
        preferredSize: const Size.fromHeight(45.0),

        // Đặt AppBar của bạn vào trong thuộc tính 'child'
        child: AppBar(
          title: Text(
            _getAppBarTitle(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ), // Có thể giảm cỡ chữ nếu cần
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
        style: TabStyle.react, // ✅ Đã áp dụng style 'react'
        backgroundColor: Colors.white,
        color: Colors.grey[600],
        activeColor: Colors.orange[600],
        height: 60,
        elevation: 8,
      ),
    );
  }
}
