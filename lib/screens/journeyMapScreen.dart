// File: journeyMapScreen.dart (ĐÃ DỌN DẸP)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Vẫn cần cho hàm init service
import 'package:collection/collection.dart'; // Vẫn cần cho hàm init service
import 'package:nhom_3_damh_lttbdd/screens/worldMapScreen.dart';

// Imports các file mới
import 'journey_map_service.dart';
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart'; // Import file constants
import 'journey_map_widgets.dart';

class JourneyMapScreen extends StatefulWidget {
  final String userId;
  const JourneyMapScreen({super.key, required this.userId});

  @override
  State<JourneyMapScreen> createState() => _JourneyMapScreenState();
}

class _JourneyMapScreenState extends State<JourneyMapScreen> {
  // === STATE CHÍNH (GIỮ LẠI) ===
  final _fabKey = GlobalKey<ExpandableFabState>();
  final _mapService = JourneyMapService(); // Khởi tạo Service
  Set<String> highlightedProvinces = {};
  bool isLoading = true;
  String? _originalSvgContent;
  String? _modifiedSvgContent;

  // === DỮ LIỆU CỨNG (ĐÃ XÓA VÀ CHUYỂN SANG constants.dart) ===
  // final List<String> allProvincesId = [ ... ]; // ĐÃ DI CHUYỂN
  // final Map<String, String> _provinceDisplayNames = { ... }; // ĐÃ DI CHUYỂN

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // === HÀM XỬ LÝ SỰ KIỆN (GIỮ LẠI) ===
  void _navigateToOSM() {
    print("Điều hướng đến WorldMapScreen...");
    Navigator.push(
      context,
      MaterialPageRoute(
        // Điều hướng sang màn hình mới và truyền userId
        builder: (context) => WorldMapScreen(userId: widget.userId),
      ),
    );
  }

  void _savePrivateLocation() {
    print('Lưu địa điểm cá nhân...');
    // TODO: Triển khai logic
  }

  void _postReview() {
    print('Đăng bài...');
    // TODO: Triển khai logic
  }

  // === LOGIC TẢI DỮ LIỆU (ĐÃ GỌN GÀNG) ===
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // 1. Tải SVG gốc
      _originalSvgContent = await rootBundle.loadString(
        'assets/maps/vietnam_34_provinces.svg',
      );

      // 2. Tải data highlight (gọi Service)
      highlightedProvinces = await _mapService.loadHighlightedProvinces(
        widget.userId,
      );

      // 3. Tô màu SVG (dùng hàm _colorSvgPaths ở dưới)
      _modifiedSvgContent = _colorSvgPaths(
        _originalSvgContent!,
        highlightedProvinces,
      );
    } catch (e) {
      print("Lỗi tải dữ liệu ban đầu: $e");
      if (mounted) {
        _modifiedSvgContent = _originalSvgContent; // Dùng bản đồ gốc nếu lỗi
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // === HÀM TẢI DỮ LIỆU (ĐÃ XÓA VÀ CHUYỂN SANG service.dart) ===
  // Future<void> _loadHighlightData() async { ... } // ĐÃ DI CHUYỂN

  // === HÀM TÔ MÀU (GIỮ LẠI) ===
  // (Giữ nguyên hàm này từ code của bạn, line 218)
  String _colorSvgPaths(String svgContent, Set<String> provinceIdsToColor) {
    String coloredSvg = svgContent;
    const String fillColor = "#ede31c"; // Giữ nguyên màu vàng của bạn
    const double fillOpacity = 0.8;

    for (String provinceId in provinceIdsToColor) {
      final pattern = RegExp('(<path[^>]*id="$provinceId"[^>]*?)(/?>)');
      coloredSvg = coloredSvg.replaceFirstMapped(pattern, (match) {
        String pathTag = match.group(1)!;
        String closing = match.group(2)!;
        pathTag = pathTag.replaceAll(RegExp(r'\sfill="[^"]*"'), '');
        pathTag = pathTag.replaceAll(RegExp(r'\sstyle="[^"]*"'), '');
        return '$pathTag fill="$fillColor" fill-opacity="$fillOpacity" $closing';
      });
    }
    return coloredSvg;
  }

  // === HÀM BUILD GIAO DIỆN (ĐÃ DỌN DẸP) ===
  @override
  Widget build(BuildContext context) {
    int visitedCount = highlightedProvinces.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Map'),
        actions: [
          IconButton(
            onPressed: () {
              /* TODO: Tải xuống */
            },
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            onPressed: () {
              /* TODO: Chia sẻ */
            },
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      // --- DÙNG WIDGET MỚI ---
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: JourneyMapFab(
        fabKey: _fabKey,
        onShowDetails: _showVisitedDetailsModal,
        onOpenOsm: _navigateToOSM,
        onSaveLocation: _savePrivateLocation,
        onPostReview: _postReview, // <-- Thêm hàm này
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                // 1. Lớp nền (Giữ nguyên từ code của bạn, line 406)
                Image.asset(
                  'assets/images/map_background.jpg',
                  fit: BoxFit.cover,
                ),
                // 2. Lớp bản đồ (Dùng widget mới)
                JourneyMapViewer(
                  modifiedSvgContent: _modifiedSvgContent,
                  originalSvgContent: _originalSvgContent,
                ),
                // 3. Lớp thống kê (Dùng widget mới)
                VisitedStatsBanner(
                  visitedCount: visitedCount,
                  totalCount: kAllProvinceIds.length, // Lấy từ constants
                ),
              ],
            ),
    );
  }

  // === CÁC HÀM HELPER (ĐÃ XÓA HOẶC GIỮ LẠI) ===

  // _formatProvinceNameToId (ĐÃ DI CHUYỂN SANG service.dart)
  // _formatProvinceIdToDisplayName (ĐÃ DI CHUYỂN SANG constants.dart)
  // _buildProvinceGrid (ĐÃ DI CHUYỂN SANG widgets.dart)

  // === HÀM HIỂN THỊ MODAL (GIỮ LẠI) ===
  // (Giữ nguyên từ code của bạn, line 551, chỉ thay đổi builder)
  void _showVisitedDetailsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // --- DÙNG WIDGET MỚI ---
        return VisitedProvincesModal(
          highlightedProvinces: highlightedProvinces,
        );
      },
    );
  }
}
