import 'package:flutter/material.dart';

/// Widget header cho trang Explore
/// Hiển thị avatar người dùng, tên, thông báo, thanh tìm kiếm và tabbar
class ExploreHeader extends StatelessWidget {
  // Thông tin người dùng
  final String userName; // Tên hiển thị
  final String userAvatarUrl; // URL avatar
  final bool isUserDataLoading; // Loading khi đang fetch dữ liệu người dùng

  // TabController để điều khiển TabBar
  final TabController tabController;

  // Callback khi nhấn vào avatar hoặc thông báo
  final VoidCallback onAvatarTap;
  final VoidCallback onNotificationTap;

  const ExploreHeader({
    Key? key,
    required this.userName,
    required this.userAvatarUrl,
    required this.isUserDataLoading,
    required this.tabController,
    required this.onAvatarTap,
    required this.onNotificationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 5), // Khoảng cách trên cùng
        _buildTopBar(), // Thanh trên cùng: avatar + tên + thông báo
        _buildSearchBar(), // Thanh tìm kiếm
        _buildTabBar(), // TabBar: "Khám phá" và "Dành cho bạn"
      ],
    );
  }

  /// 🔹 Thanh trên cùng: avatar + tên + icon thông báo
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Avatar + Tên
          InkWell(
            onTap: onAvatarTap,
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nếu đang load dữ liệu người dùng thì hiển thị loading spinner
                  isUserDataLoading
                      ? const CircleAvatar(
                          radius: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : CircleAvatar(
                          radius: 20,
                          backgroundImage: _getAvatarProvider(), // avatar user
                        ),
                  const SizedBox(width: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Icon thông báo
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: Colors.grey[800],
              size: 28,
            ),
            onPressed: onNotificationTap,
          ),
        ],
      ),
    );
  }

  /// 🔹 Thanh tìm kiếm
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  /// 🔹 TabBar: "Khám phá" và "Dành cho bạn"
  Widget _buildTabBar() {
    return TabBar(
      controller: tabController,
      tabs: const [
        Tab(text: "Khám phá"),
        Tab(text: "Dành cho bạn"),
      ],
      labelColor: Colors.orange, // màu tab được chọn
      unselectedLabelColor: Colors.grey, // màu tab chưa chọn
      indicatorColor: Colors.orange, // màu gạch dưới tab được chọn
    );
  }

  /// 🔹 Lấy ImageProvider phù hợp cho avatar
  ImageProvider _getAvatarProvider() {
    // Nếu URL là HTTP thì dùng NetworkImage, nếu không dùng AssetImage
    if (userAvatarUrl.startsWith('http')) {
      return NetworkImage(userAvatarUrl);
    }
    return AssetImage(userAvatarUrl);
  }
}
