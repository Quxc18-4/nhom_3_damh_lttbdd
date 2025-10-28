// File: journey_map_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'journey_map_constants.dart'; // Import file constants

// === WIDGET 1: NÚT FAB MỞ RỘNG ===
// === DI CHUYỂN TỪ build() > ExpandableFab (lines 262-399) ===
class JourneyMapFab extends StatelessWidget {
  final GlobalKey<ExpandableFabState> fabKey;
  final VoidCallback onShowDetails;
  final VoidCallback onOpenOsm;
  final VoidCallback onSaveLocation;
  final VoidCallback onPostReview;

  const JourneyMapFab({
    Key? key,
    required this.fabKey,
    required this.onShowDetails,
    required this.onOpenOsm,
    required this.onSaveLocation,
    required this.onPostReview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandableFab(
      key: fabKey,
      pos: ExpandableFabPos.left,
      type: ExpandableFabType.up,
      distance: 80.0, // Bạn config 80.0, nhưng ảnh chụp là 70.0? Giữ 80.0
      openButtonBuilder: RotateFloatingActionButtonBuilder(
        child: const Icon(Icons.menu),
        fabSize: ExpandableFabSize.regular,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
      ),
      closeButtonBuilder: RotateFloatingActionButtonBuilder(
        child: const Icon(Icons.close),
        fabSize: ExpandableFabSize.regular,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
      ),
      overlayStyle: ExpandableFabOverlayStyle(
        color: Colors.black.withOpacity(0.4),
        blur: 5,
      ),
      children: [
        // --- 1. Xem chi tiết --- (Giữ nguyên từ code của bạn)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onShowDetails, // <-- Dùng callback
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.details_outlined, color: Colors.white, size: 24),
                  SizedBox(width: 12),
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
        // --- 2. Mở bản đồ khu vực --- (Giữ nguyên từ code của bạn)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpenOsm, // <-- Dùng callback
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, color: Colors.white, size: 24),
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
        // --- 3. Lưu địa điểm cá nhân --- (Giữ nguyên từ code của bạn)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSaveLocation, // <-- Dùng callback
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_add_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
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
        // --- 4. Đăng bài công khai --- (Giữ nguyên từ code của bạn)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPostReview, // <-- Dùng callback
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.post_add_outlined, color: Colors.white, size: 24),
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
class VisitedProvincesModal extends StatelessWidget {
  final Set<String> highlightedProvinces;

  const VisitedProvincesModal({Key? key, required this.highlightedProvinces})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Logic từ _showVisitedDetailsModal (lines 553-565)
    final List<String> visitedIds = highlightedProvinces.toList();
    final List<String> unvisitedIds = kAllProvinceIds
        .where((id) => !highlightedProvinces.contains(id))
        .toList();
    final List<String> visitedNames =
        visitedIds.map(formatProvinceIdToName).toList()..sort();
    final List<String> unvisitedNames =
        unvisitedIds.map(formatProvinceIdToName).toList()..sort();

    // UI từ _showVisitedDetailsModal (lines 568-646)
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Chi tiết khám phá',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Các tỉnh/thành phố đã đi (${visitedNames.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildProvinceGrid(visitedNames), // Grid đã đi
                    const SizedBox(height: 20),
                    Text(
                      'Các tỉnh/thành phố chưa đi (${unvisitedNames.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildProvinceGrid(unvisitedNames), // Grid chưa đi
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
  Widget _buildProvinceGrid(List<String> provinces) {
    if (provinces.isEmpty) {
      return const Text(
        ' (Không có)',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 3.5 / 1,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
      ),
      itemCount: provinces.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Text(
              provinces[index],
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

// === WIDGET 3: KHUNG HIỂN THỊ BẢN ĐỒ ===
// === DI CHUYỂN TỪ build() > body > Stack > InteractiveViewer (lines 413-442) ===
class JourneyMapViewer extends StatelessWidget {
  final String? modifiedSvgContent;
  final String? originalSvgContent;

  const JourneyMapViewer({
    Key? key,
    this.modifiedSvgContent,
    this.originalSvgContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (modifiedSvgContent != null)
      return InteractiveViewer(
        minScale: 1.0,
        maxScale: 5.0,
        child: SvgPicture.string(
          modifiedSvgContent!,
          fit: BoxFit.contain,
          placeholderBuilder: (context) =>
              const Center(child: Text("Đang tải bản đồ...")),
        ),
      );
    else if (originalSvgContent != null)
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
    else
      return const Center(child: Text("Không thể tải bản đồ"));
  }
}

// === WIDGET 4: BANNER THỐNG KÊ ===
// === DI CHUYỂN TỪ build() > body > Stack > Positioned (lines 445-468) ===
class VisitedStatsBanner extends StatelessWidget {
  final int visitedCount;
  final int totalCount;

  const VisitedStatsBanner({
    Key? key,
    required this.visitedCount,
    required this.totalCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
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
