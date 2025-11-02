import 'package:flutter/material.dart';

class ExploreHeader extends StatelessWidget {
  final String userName;
  final String userAvatarUrl;
  final bool isUserDataLoading;
  final TabController tabController;
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
        const SizedBox(height: 5),
        _buildTopBar(),
        _buildSearchBar(),
        _buildTabBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          InkWell(
            onTap: onAvatarTap,
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isUserDataLoading
                      ? const CircleAvatar(
                          radius: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : CircleAvatar(
                          radius: 20,
                          backgroundImage: _getAvatarProvider(),
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

  Widget _buildTabBar() {
    return TabBar(
      controller: tabController,
      tabs: const [
        Tab(text: "Khám phá"),
        Tab(text: "Dành cho bạn"),
      ],
      labelColor: Colors.orange,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.orange,
    );
  }

  ImageProvider _getAvatarProvider() {
    if (userAvatarUrl.startsWith('http')) {
      return NetworkImage(userAvatarUrl);
    }
    return AssetImage(userAvatarUrl);
  }
}
