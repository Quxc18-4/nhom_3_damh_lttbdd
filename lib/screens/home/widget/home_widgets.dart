// File: screens/home/widget/home_widgets.dart

import 'package:flutter/material.dart'; // Thư viện chính của Flutter
import 'package:intl/intl.dart'; // Định dạng ngày giờ (DateFormat)
// Cập nhật các đường dẫn import này
import 'package:nhom_3_damh_lttbdd/model/activity.dart'; // Model Activity (thời gian, tiêu đề, icon)
import 'package:nhom_3_damh_lttbdd/model/banner.dart'; // Model Banner (title, content, imageUrl, endDate)
import 'package:nhom_3_damh_lttbdd/screens/bannerDetailScreen.dart'; // Màn hình chi tiết banner

// === WIDGET 1: HEADER CHÍNH ===
class HomeHeader extends StatelessWidget { // Widget không có trạng thái
  final String userNickname; // Tên người dùng hiện tại
  final int unreadCount; // Số thông báo chưa đọc
  final VoidCallback onNotificationTap; // Hàm gọi khi nhấn icon chuông
  final TextEditingController searchController; // Controller cho ô tìm kiếm (chưa dùng)

  // Tài sản (assets) - giữ nguyên từ file gốc
  static const String _ASSET_AVATAR = 'assets/images/image 8.png'; // Đường dẫn ảnh avatar

  const HomeHeader({ // Constructor
    Key? key,
    required this.userNickname,
    required this.unreadCount,
    required this.onNotificationTap,
    required this.searchController,
  }) : super(key: key);

  String get _greeting { // Getter tính lời chào theo giờ
    final hour = DateTime.now().hour; // Lấy giờ hiện tại (0-23)
    if (hour < 12) return 'Chào buổi sáng'; // Trước 12h
    if (hour < 18) return 'Chào buổi chiều'; // Từ 12h đến trước 18h
    return 'Chào buổi tối'; // Từ 18h trở đi
  }

  String get _formattedDate { // Getter định dạng ngày + thứ
    final today = DateTime.now(); // Ngày hiện tại
    final dayOfWeek = DateFormat('EEEE', 'vi_VN').format(today); // Thứ (ví dụ: Thứ Hai)
    final date = DateFormat('dd MMMM yyyy', 'vi_VN').format(today); // Ngày (03 Tháng Mười Một 2025)
    return '${dayOfWeek}, ${date.replaceAll(',', '')}'; // Ghép: Thứ Hai, 03 Tháng Mười Một 2025
  }

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Container( // Container chính của header
      decoration: const BoxDecoration( // Nền và bo góc
        color: Color(0xFFFFE0B2), // Màu cam nhạt
        borderRadius: BorderRadius.only( // Bo 2 góc dưới
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20), // Padding: trên nhiều hơn (do status bar)
      child: Column( // Cột dọc chứa tất cả
        crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
        children: [
          Row( // DÒNG 1: Ngày + QR + Thông báo
            children: [
              const Icon(Icons.calendar_month, size: 20, color: Colors.black54), // Icon lịch
              const SizedBox(width: 8), // Khoảng cách
              Text( // Hiển thị ngày + thứ
                _formattedDate,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const Spacer(), // Đẩy các icon sang phải
              IconButton( // Nút QR (chưa có chức năng)
                icon: const Icon(
                  Icons.qr_code_scanner_outlined,
                  color: Colors.black,
                ),
                onPressed: () {}, // Chưa làm gì
                padding: EdgeInsets.zero, // Không padding
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32), // Kích thước nhỏ
              ),
              Stack( // Xếp chồng: icon + badge
                children: [
                  IconButton( // Icon chuông
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.black,
                    ),
                    onPressed: onNotificationTap, // Gọi hàm từ ngoài vào
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  if (unreadCount > 0) // Badge số lượng (nếu > 0)
                    Positioned( // Đặt ở góc trên phải
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2), // Padding nhỏ
                        decoration: BoxDecoration(
                          color: Colors.red, // Màu đỏ
                          borderRadius: BorderRadius.circular(6), // Bo tròn
                          border: Border.all(color: Colors.white, width: 1.5), // Viền trắng
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          unreadCount.toString(), // Số thông báo
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
          const SizedBox(height: 12), // Khoảng cách dọc
          Row( // DÒNG 2: Avatar + Lời chào
            children: [
              ClipOval( // Ảnh tròn
                child: Image.asset(
                  _ASSET_AVATAR, // Ảnh từ assets
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover, // Cắt vừa khung
                  errorBuilder: (context, error, stackTrace) =>
                      const CircleAvatar(radius: 20, child: Icon(Icons.person)), // Nếu lỗi → icon người
                ),
              ),
              const SizedBox(width: 10), // Khoảng cách
              Text(
                '$_greeting, ${userNickname.isNotEmpty ? userNickname : "Mydei"}!', // Lời chào + tên
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800), // Màu cam đậm
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // Khoảng cách
          TextField( // Ô TÌM KIẾM
            // controller: searchController, // Chưa kết nối
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...', // Placeholder
              prefixIcon: const Icon(Icons.search, color: Colors.grey), // Icon kính lúp
              filled: true, // Có nền
              fillColor: Colors.white, // Màu trắng
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ), // Padding nội dung
              border: OutlineInputBorder( // Viền
                borderRadius: BorderRadius.circular(12), // Bo góc
                borderSide: BorderSide.none, // Không viền
              ),
            ),
          ),
          const SizedBox(height: 12), // Khoảng cách
          SingleChildScrollView( // GỢI Ý TÌM KIẾM (CHIP)
            scrollDirection: Axis.horizontal, // Cuộn ngang
            child: Row(
              children: [
                _buildSuggestionChip('Hotel Đà Lạt', const Color(0xFFFFCC80)), // Chip 1
                _buildSuggestionChip(
                  'Thuê xe tại Huế',
                  const Color(0xFFB3E5FC),
                ), // Chip 2
                _buildSuggestionChip(
                  'Vé máy bay giá rẻ',
                  const Color(0xFFFFAB91),
                ), // Chip 3
                _buildSuggestionChip('Tour Đà Lạt', const Color(0xFFC5E1A5)), // Chip 4
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label, Color color) { // Hàm tạo chip gợi ý
    return Container( // Container cho mỗi chip
      margin: const EdgeInsets.only(right: 8), // Cách nhau 8dp
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Padding trong
      decoration: BoxDecoration(
        color: color, // Màu nền chip
        borderRadius: BorderRadius.circular(16), // Bo tròn
      ),
      child: Text(
        label, // Nội dung chip
        style: const TextStyle(color: Colors.white, fontSize: 14), // Chữ trắng
      ),
    );
  }
}

// === WIDGET 2: PHẦN DỊCH VỤ ===
class ServiceSection extends StatelessWidget { // Widget không có trạng thái
  final List<Map<String, dynamic>> services; // Danh sách dịch vụ (icon, title, bgColor)
  const ServiceSection({Key? key, required this.services}) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Column( // Cột dọc
      crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
      children: [
        const Padding( // Tiêu đề "Dịch vụ"
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Text(
            'Dịch vụ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        SizedBox( // Danh sách ngang các dịch vụ
          height: 100, // Chiều cao cố định
          child: ListView.builder(
            scrollDirection: Axis.horizontal, // Cuộn ngang
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding hai bên
            itemCount: services.length, // Số lượng dịch vụ
            itemBuilder: (context, index) { // Tạo từng item
              final service = services[index]; // Lấy dịch vụ thứ index
              final String? assetPath = service['assetPath'] as String?; // Đường dẫn ảnh

              final serviceIcon = (assetPath != null && assetPath.isNotEmpty) // Xử lý icon
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
                  (service["bgColor"] as Color?) ?? Colors.grey.shade200; // Màu nền

              return Container( // Mỗi dịch vụ
                width: 70, // Chiều rộng cố định
                margin: const EdgeInsets.only(right: 15), // Cách nhau
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar( // Vòng tròn chứa icon
                      radius: 25,
                      backgroundColor: bgColor,
                      child: serviceIcon,
                    ),
                    const SizedBox(height: 4), // Khoảng cách
                    Text( // Tiêu đề dịch vụ
                      service["title"].toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2, // Tối đa 2 dòng
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
class JourneyMapPreview extends StatelessWidget { // Widget không có trạng thái
  final bool isLoadingMap; // Đang tải dữ liệu
  final int visitedCount; // Số tỉnh đã đi
  final int totalCount; // Tổng số tỉnh
  final VoidCallback onTap; // Nhấn để vào bản đồ

  const JourneyMapPreview({
    Key? key,
    required this.isLoadingMap,
    required this.visitedCount,
    required this.totalCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return InkWell( // Có hiệu ứng nhấn
      onTap: onTap, // Gọi hàm từ ngoài
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row( // Dòng tiêu đề
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
            isLoadingMap // Hiển thị trạng thái
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
class TripPlanPreview extends StatelessWidget { // Widget không có trạng thái
  final DateTime startDate; // Ngày bắt đầu
  final List<List<Activity>> dayActivitiesPreview; // 3 ngày hoạt động
  final VoidCallback onNavigate; // Nhấn mũi tên

  const TripPlanPreview({
    Key? key,
    required this.startDate,
    required this.dayActivitiesPreview,
    required this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    final day1 = startDate; // Ngày 1
    final day2 = startDate.add(const Duration(days: 1)); // Ngày 2
    final day3 = startDate.add(const Duration(days: 2)); // Ngày 3

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding( // Tiêu đề + nút sang chi tiết
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
        Padding( // Hiển thị khoảng ngày
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '${day1.day.toString().padLeft(2, '0')}/${day1.month.toString().padLeft(2, '0')}/${day1.year} - '
            '${day3.day.toString().padLeft(2, '0')}/${day3.month.toString().padLeft(2, '0')}/${day3.year}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        const SizedBox(height: 6),
        DefaultTabController( // Tab 3 ngày
          length: 3, // 3 tab
          initialIndex: 0, // Mở tab đầu tiên
          child: Column(
            children: [
              Container( // TabBar
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
              Container( // Nội dung tab
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
                    physics: const NeverScrollableScrollPhysics(), // Không cuộn tay
                    children: List.generate(3, (dayIndex) { // Tạo 3 tab nội dung
                      final activities = dayActivitiesPreview[dayIndex]; // Lấy hoạt động ngày đó
                      if (activities.isEmpty) { // Không có hoạt động
                        return Center(
                          child: Text(
                            'Chưa có hoạt động nào cho Day ${dayIndex + 1}',
                          ),
                        );
                      }
                      return ListView.builder( // Có hoạt động → hiển thị danh sách
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
class _ActivityPreviewItem extends StatelessWidget { // Widget con
  final Activity activity; // Một hoạt động
  const _ActivityPreviewItem({Key? key, required this.activity})
    : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Container( // Container cho mỗi hoạt động
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 8.0,
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Nền xanh nhạt
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF64B5F6),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 14, color: Color(0xFF1976D2)), // Icon đồng hồ
          const SizedBox(width: 6),
          Text(
            activity.time, // Giờ
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded( // Tiêu đề chiếm hết chỗ
            child: Text(
              activity.title,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              overflow: TextOverflow.ellipsis, // Cắt nếu dài
            ),
          ),
          Container( // Vòng tròn icon loại hoạt động
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.15), // Nền mờ
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                activity.icon,
                size: 16,
                color: activity.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === WIDGET 5: TIN TỨC & ƯU ĐÃI ===
class NewsFeedSection extends StatelessWidget { // Widget không có trạng thái
  final List<BannerModel> activeBanners; // Danh sách banner
  const NewsFeedSection({Key? key, required this.activeBanners})
    : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding( // Tiêu đề
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tin Tức & Ưu Đãi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              GestureDetector(
                onTap: () {}, // Chưa làm
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        if (activeBanners.isEmpty) // Không có banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Text(
              'Hiện chưa có tin tức nào.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else // Có banner
          ...activeBanners
              .map((banner) => _BannerItem(banner: banner))
              .toList(), // Tạo từng item
      ],
    );
  }
}

// === WIDGET 5.1: ITEM BANNER ===
class _BannerItem extends StatelessWidget { // Widget con
  final BannerModel banner;
  const _BannerItem({Key? key, required this.banner}) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return GestureDetector( // Có thể nhấn
      onTap: () {
        Navigator.push( // Mở màn hình chi tiết
          context,
          MaterialPageRoute(
            builder: (context) => BannerDetailScreen(banner: banner),
          ),
        );
      },
      child: Container( // Container banner
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
            ClipRRect( // Ảnh
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
            Expanded( // Nội dung
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