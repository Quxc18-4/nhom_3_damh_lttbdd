// File: journey_map_widgets.dart

import 'package:flutter/material.dart'; // Thư viện chính của Flutter
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart'; // Nút FAB mở rộng
import 'package:flutter_svg/flutter_svg.dart'; // Hiển thị file SVG
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart'; // Import file constants

// === WIDGET 1: NÚT FAB MỞ RỘNG ===
// === DI CHUYỂN TỪ build() > ExpandableFab (lines 262-399) ===
class JourneyMapFab extends StatelessWidget { // Widget nút FAB mở rộng
  final GlobalKey<ExpandableFabState> fabKey; // Key để điều khiển trạng thái FAB
  final VoidCallback onShowDetails; // Hàm gọi khi nhấn "Xem chi tiết"
  final VoidCallback onOpenOsm; // Hàm gọi khi nhấn "Mở bản đồ khu vực"
  final VoidCallback onSaveLocation; // Hàm gọi khi nhấn "Lưu địa điểm"
  final VoidCallback onPostReview; // Hàm gọi khi nhấn "Đăng bài review"

  const JourneyMapFab({ // Constructor
    Key? key,
    required this.fabKey,
    required this.onShowDetails,
    required this.onOpenOsm,
    required this.onSaveLocation,
    required this.onPostReview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện FAB
    return ExpandableFab( // Nút FAB mở rộng
      key: fabKey, // Key để điều khiển mở/đóng
      pos: ExpandableFabPos.left, // Vị trí: bên trái
      type: ExpandableFabType.up, // Mở lên trên
      distance: 80.0, // Khoảng cách giữa các nút con
      openButtonBuilder: RotateFloatingActionButtonBuilder( // Nút mở
        child: const Icon(Icons.menu), // Icon menu
        fabSize: ExpandableFabSize.regular, // Kích thước chuẩn
        backgroundColor: Colors.orange, // Màu nền cam
        foregroundColor: Colors.white, // Màu icon trắng
        shape: const CircleBorder(), // Hình tròn
      ),
      closeButtonBuilder: RotateFloatingActionButtonBuilder( // Nút đóng
        child: const Icon(Icons.close), // Icon đóng
        fabSize: ExpandableFabSize.regular,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
      ),
      overlayStyle: ExpandableFabOverlayStyle( // Lớp phủ khi mở
        color: Colors.black.withOpacity(0.4), // Màu đen mờ 40%
        blur: 5, // Làm mờ nền
      ),
      children: [ // Danh sách các nút con
        // --- 1. Xem chi tiết ---
        Material( // Vùng nhấn
          color: Colors.transparent, // Trong suốt
          child: InkWell( // Hiệu ứng nhấn
            onTap: onShowDetails, // Gọi hàm từ ngoài vào
            borderRadius: BorderRadius.circular(28), // Bo góc
            child: Container( // Nút con
              height: 56, // Chiều cao
              padding: const EdgeInsets.symmetric(horizontal: 16), // Padding ngang
              decoration: BoxDecoration(
                color: Colors.blue, // Màu xanh
                borderRadius: BorderRadius.circular(28), // Bo góc
              ),
              child: const Row( // Dòng icon + chữ
                mainAxisSize: MainAxisSize.min, // Chỉ chiếm không gian cần thiết
                children: [
                  Icon(Icons.details_outlined, color: Colors.white, size: 24), // Icon chi tiết
                  SizedBox(width: 12), // Khoảng cách
                  Text(
                    'Xem chi tiết',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // --- 2. Mở bản đồ khu vực ---
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpenOsm, // Gọi hàm từ ngoài
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green, // Màu xanh lá
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, color: Colors.white, size: 24), // Icon địa cầu
                  SizedBox(width: 12),
                  Text(
                    'Mở bản đồ khu vực',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // --- 3. Lưu địa điểm cá nhân ---
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSaveLocation, // Gọi hàm từ ngoài
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.teal, // Màu xanh ngọc
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_add_outlined,
                    color: Colors.white,
                    size: 24,
                  ), // Icon lưu
                  SizedBox(width: 12),
                  Text(
                    'Lưu địa điểm cá nhân',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // --- 4. Đăng bài công khai ---
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPostReview, // Gọi hàm từ ngoài
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.purple, // Màu tím
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.post_add_outlined, color: Colors.white, size: 24), // Icon đăng bài
                  SizedBox(width: 12),
                  Text(
                    'Đăng bài review công khai',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// === WIDGET 2: MODAL HIỂN THỊ CHI TIẾT ===
// === DI CHUYỂN TỪ _showVisitedDetailsModal và _buildProvinceGrid (lines 514-647) ===
class VisitedProvincesModal extends StatelessWidget { // Modal chi tiết tỉnh đã đi
  final Set<String> highlightedProvinces; // Tập hợp ID tỉnh đã highlight

  const VisitedProvincesModal({Key? key, required this.highlightedProvinces})
    : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện modal
    // Logic từ _showVisitedDetailsModal (lines 553-565)
    final List<String> visitedIds = highlightedProvinces.toList(); // Chuyển Set → List
    final List<String> unvisitedIds = kAllProvinceIds // Lấy danh sách tỉnh chưa đi
        .where((id) => !highlightedProvinces.contains(id))
        .toList();
    final List<String> visitedNames =
        visitedIds.map(formatProvinceIdToName).toList()..sort(); // Chuyển ID → tên, sắp xếp
    final List<String> unvisitedNames =
        unvisitedIds.map(formatProvinceIdToName).toList()..sort(); // Tương tự

    // UI từ _showVisitedDetailsModal (lines 568-646)
    return ConstrainedBox( // Giới hạn chiều cao
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8, // Tối đa 80% màn hình
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Padding toàn bộ
        child: Column(
          mainAxisSize: MainAxisSize.min, // Chỉ chiếm không gian cần thiết
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center( // Thanh kéo modal
              child: Container(
                width: 40, // Chiều rộng
                height: 5, // Chiều cao
                decoration: BoxDecoration(
                  color: Colors.grey[300], // Màu xám nhạt
                  borderRadius: BorderRadius.circular(10), // Bo góc
                ),
              ),
            ),
            const SizedBox(height: 16), // Khoảng cách
            const Center( // Tiêu đề
              child: Text(
                'Chi tiết khám phá',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Expanded( // Nội dung chính, có thể cuộn
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text( // Tiêu đề "Đã đi"
                      'Các tỉnh/thành phố đã đi (${visitedNames.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildProvinceGrid(visitedNames), // Grid tỉnh đã đi
                    const SizedBox(height: 20),
                    Text( // Tiêu đề "Chưa đi"
                      'Các tỉnh/thành phố chưa đi (${unvisitedNames.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildProvinceGrid(unvisitedNames), // Grid tỉnh chưa đi
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === DI CHUYỂN TỪ _buildProvinceGrid (lines 514-549) ===
  // (Trở thành hàm private của widget này)
  Widget _buildProvinceGrid(List<String> provinces) { // Tạo lưới tỉnh
    if (provinces.isEmpty) { // Nếu không có tỉnh
      return const Text(
        ' (Không có)',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }
    return GridView.builder( // Lưới tỉnh
      physics: const NeverScrollableScrollPhysics(), // Không cuộn riêng
      shrinkWrap: true, // Chỉ chiếm không gian cần thiết
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 cột
        childAspectRatio: 3.5 / 1, // Tỷ lệ chiều rộng / cao
        mainAxisSpacing: 8.0, // Khoảng cách dọc
        crossAxisSpacing: 8.0, // Khoảng cách ngang
      ),
      itemCount: provinces.length, // Số tỉnh
      itemBuilder: (context, index) { // Tạo từng ô
        return Container( // Ô tỉnh
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100], // Màu nền nhạt
            borderRadius: BorderRadius.circular(12), // Bo góc
            border: Border.all(color: Colors.grey[300]!), // Viền
          ),
          child: Center(
            child: Text(
              provinces[index], // Tên tỉnh
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // Cắt nếu dài
            ),
          ),
        );
      },
    );
  }
}

// === WIDGET 3: KHUNG HIỂN THỊ BẢN ĐỒ ===
// === DI CHUYỂN TỪ build() > body > Stack > InteractiveViewer (lines 413-442) ===
class JourneyMapViewer extends StatelessWidget { // Widget hiển thị bản đồ SVG
  final String? modifiedSvgContent; // SVG đã được tô màu
  final String? originalSvgContent; // SVG gốc (nếu có)

  const JourneyMapViewer({
    Key? key,
    this.modifiedSvgContent,
    this.originalSvgContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện bản đồ
    if (modifiedSvgContent != null) // Nếu có SVG đã tô
      return InteractiveViewer( // Cho phép zoom, kéo
        minScale: 1.0, // Thu nhỏ tối thiểu
        maxScale: 5.0, // Phóng to tối đa
        child: SvgPicture.string( // Hiển thị SVG
          modifiedSvgContent!,
          fit: BoxFit.contain, // Vừa khung
          placeholderBuilder: (context) =>
              const Center(child: Text("Đang tải bản đồ...")), // Đang tải
        ),
      );
    else if (originalSvgContent != null) // Nếu có SVG gốc
      return InteractiveViewer(
        minScale: 1.0,
        maxScale: 5.0,
        child: SvgPicture.string(
          originalSvgContent!,
          fit: BoxFit.contain,
          placeholderBuilder: (context) =>
              const Center(child: Text("Đang tải bản đồ...")),
        ),
      );
    else // Không có gì
      return const Center(child: Text("Không thể tải bản đồ"));
  }
}

// === WIDGET 4: BANNER THỐNG KÊ ===
// === DI CHUYỂN TỪ build() > body > Stack > Positioned (lines 445-468) ===
class VisitedStatsBanner extends StatelessWidget { // Banner thống kê tỉnh đã đi
  final int visitedCount; // Số tỉnh đã đi
  final int totalCount; // Tổng số tỉnh

  const VisitedStatsBanner({
    Key? key,
    required this.visitedCount,
    required this.totalCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng banner
    return Positioned( // Đặt ở trên cùng
      top: 10, // Cách đỉnh 10dp
      left: 16, // Cách trái 16dp
      right: 16, // Cách phải 16dp
      child: Container( // Khung banner
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Padding
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6), // Màu đen mờ 60%
          borderRadius: BorderRadius.circular(8), // Bo góc
        ),
        child: Text( // Văn bản thống kê
          // Giữ nguyên text từ code của bạn
          'Đã khám phá $visitedCount/$totalCount tỉnh thành tại Việt Nam',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}