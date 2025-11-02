// File: screens/journey_map/journeyMapScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import 'package:nhom_3_damh_lttbdd/screens/world_map/worldMapScreen.dart';

// Imports các file mới với đường dẫn đã cập nhật
import 'service/journey_map_service.dart';
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart';
import 'widget/journey_map_widgets.dart';
import 'helper/svg_color_helper.dart'; // <-- IMPORT FILE HELPER MỚI

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

      // 3. Tô màu SVG (dùng hàm từ helper)
      _modifiedSvgContent = colorSvgPaths(
        // <-- SỬ DỤNG HÀM TỪ HELPER
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

  // === HÀM TÔ MÀU (ĐÃ XÓA VÀ CHUYỂN SANG helper/svg_color_helper.dart) ===
  // String _colorSvgPaths(...) { ... } // <-- ĐÃ DI CHUYỂN

  // === HÀM BUILD GIAO DIỆN (GIỮ NGUYÊN) ===
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
        onPostReview: _postReview,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                // 1. Lớp nền
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

  // === HÀM HIỂN THỊ MODAL (GIỮ NGUYÊN) ===
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
