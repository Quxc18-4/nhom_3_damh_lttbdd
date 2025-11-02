// File: screens/home/widget/home_widgets.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Cập nhật các đường dẫn import này
import 'package:nhom_3_damh_lttbdd/model/activity.dart';
import 'package:nhom_3_damh_lttbdd/model/banner.dart';
import 'package:nhom_3_damh_lttbdd/screens/bannerDetailScreen.dart';

// === WIDGET 1: HEADER CHÍNH ===
class HomeHeader extends StatelessWidget {
  final String userNickname;
  final int unreadCount;
  final VoidCallback onNotificationTap;
  final TextEditingController searchController; // Có thể truyền controller

  // Tài sản (assets) - giữ nguyên từ file gốc
  static const String _ASSET_AVATAR = 'assets/images/image 8.png';

  const HomeHeader({
    Key? key,
    required this.userNickname,
    required this.unreadCount,
    required this.onNotificationTap,
    required this.searchController,
  }) : super(key: key);

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String get _formattedDate {
    final today = DateTime.now();
    final dayOfWeek = DateFormat('EEEE', 'vi_VN').format(today);
    final date = DateFormat('dd MMMM yyyy', 'vi_VN').format(today);
    return '${dayOfWeek}, ${date.replaceAll(',', '')}';
  }

  @override
  Widget build(BuildContext context) {
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
                _formattedDate,
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
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.black,
                    ),
                    onPressed: onNotificationTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  if (unreadCount > 0)
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
                          unreadCount.toString(),
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
                '$_greeting, ${userNickname.isNotEmpty ? userNickname : "Mydei"}!',
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
            // controller: searchController,
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
}

// === WIDGET 2: PHẦN DỊCH VỤ ===
class ServiceSection extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  const ServiceSection({Key? key, required this.services}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
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
}

// === WIDGET 3: XEM TRƯỚC JOURNEY MAP ===
class JourneyMapPreview extends StatelessWidget {
  final bool isLoadingMap;
  final int visitedCount;
  final int totalCount;
  final VoidCallback onTap;

  const JourneyMapPreview({
    Key? key,
    required this.isLoadingMap,
    required this.visitedCount,
    required this.totalCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            isLoadingMap
                ? const Text(
                    'Đang tải dữ liệu bản đồ...',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  )
                : Text(
                    'Đã khám phá $visitedCount/$totalCount tỉnh thành tại Việt Nam',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
          ],
        ),
      ),
    );
  }
}

// === WIDGET 4: XEM TRƯỚC LỊCH TRÌNH ===
class TripPlanPreview extends StatelessWidget {
  final DateTime startDate;
  final List<List<Activity>> dayActivitiesPreview;
  final VoidCallback onNavigate;

  const TripPlanPreview({
    Key? key,
    required this.startDate,
    required this.dayActivitiesPreview,
    required this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final day1 = startDate;
    final day2 = startDate.add(const Duration(days: 1));
    final day3 = startDate.add(const Duration(days: 2));

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
                onTap: onNavigate,
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
        DefaultTabController(
          length: 3,
          initialIndex: 0,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
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
                      final activities = dayActivitiesPreview[dayIndex];
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
                          return _ActivityPreviewItem(
                            activity: activities[index],
                          ); // Gọi widget con
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
}

// === WIDGET 4.1: ITEM HOẠT ĐỘNG (DÙNG TRONG PREVIEW) ===
class _ActivityPreviewItem extends StatelessWidget {
  final Activity activity;
  const _ActivityPreviewItem({Key? key, required this.activity})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 8.0,
      ), // Giảm padding
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12), // Giảm bo góc
        border: Border.all(
          color: const Color(0xFF64B5F6),
          width: 1.0,
        ), // Mỏng hơn
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 14, color: Color(0xFF1976D2)),
          const SizedBox(width: 6),
          Text(
            activity.time,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13, // Nhỏ hơn
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              activity.title,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 28, // Nhỏ hơn
            height: 28,
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                activity.icon,
                size: 16,
                color: activity.color,
              ), // Nhỏ hơn
            ),
          ),
        ],
      ),
    );
  }
}

// === WIDGET 5: TIN TỨC & ƯU ĐÃI ===
class NewsFeedSection extends StatelessWidget {
  final List<BannerModel> activeBanners;
  const NewsFeedSection({Key? key, required this.activeBanners})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                onTap: () {},
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        if (activeBanners.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Text(
              'Hiện chưa có tin tức nào.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ...activeBanners
              .map((banner) => _BannerItem(banner: banner))
              .toList(),
      ],
    );
  }
}

// === WIDGET 5.1: ITEM BANNER ===
class _BannerItem extends StatelessWidget {
  final BannerModel banner;
  const _BannerItem({Key? key, required this.banner}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
}
