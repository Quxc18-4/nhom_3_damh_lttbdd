import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:nhom_3_damh_lttbdd/screens/profileScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/exploreScreen.dart';

class HomePage extends StatefulWidget {
  // 1. Dòng này của bạn đã đúng
  final String userId;

  // 2. SỬA LẠI CONSTRUCTOR ĐỂ NHẬN userId
  const HomePage({
    Key? key,
    required this.userId, // Thêm 'required this.userId' vào đây
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> samplePlaces = [
    {
      "name": "Vịnh Hạ Long",
      "location": "Quảng Ninh, Việt Nam",
      "rating": 4.8,
      "image":
          "https://photo.znews.vn/w1920/Uploaded/mdf_eioxrd/2021_07_06/2.jpg",
    },
    {
      "name": "Phú Quốc Island",
      "location": "Kiên Giang, Việt Nam",
      "rating": 4.6,
      "image":
          "https://photo.znews.vn/w1920/Uploaded/mdf_eioxrd/2021_07_06/2.jpg",
    },
    {
      "name": "Đà Lạt City",
      "location": "Lâm Đồng, Việt Nam",
      "rating": 4.7,
      "image":
          "https://photo.znews.vn/w1920/Uploaded/mdf_eioxrd/2021_07_06/2.jpg",
    },
  ];

  Widget _buildHomeContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm địa điểm...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: samplePlaces.length,
            itemBuilder: (context, index) {
              final place = samplePlaces[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                elevation: 3,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bấm vào: ${place["name"]}')),
                    );
                  },
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Image.network(
                          place["image"],
                          width: 120,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place["name"],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                place["location"],
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                  Text('${place["rating"]} / 5.0'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
        return ExploreScreen();
      case 2:
        return _buildBookingContent();
      case 3:
        return _buildSavedContent();
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
