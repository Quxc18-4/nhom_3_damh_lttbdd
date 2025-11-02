// File: screens/journey_map/journeyMapScreen.dart

import 'package:flutter/material.dart'; // Thư viện chính của Flutter
import 'package:flutter/services.dart' show rootBundle; // Đọc file từ assets
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart'; // FAB mở rộng

import 'package:nhom_3_damh_lttbdd/screens/world_map/worldMapScreen.dart'; // Màn hình bản đồ thế giới

// Imports các file mới với đường dẫn đã cập nhật
import 'service/journey_map_service.dart'; // Service xử lý dữ liệu bản đồ
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart'; // Hằng số tỉnh thành
import 'widget/journey_map_widgets.dart'; // Các widget con đã tách
import 'helper/svg_color_helper.dart'; // Helper tô màu SVG

class JourneyMapScreen extends StatefulWidget { // Màn hình bản đồ hành trình
  final String userId; // ID người dùng
  const JourneyMapScreen({super.key, required this.userId});

  @override
  State<JourneyMapScreen> createState() => _JourneyMapScreenState(); // Tạo state
}

class _JourneyMapScreenState extends State<JourneyMapScreen> { // State của màn hình
  // === STATE CHÍNH (GIỮ LẠI) ===
  final _fabKey = GlobalKey<ExpandableFabState>(); // Key điều khiển FAB
  final _mapService = JourneyMapService(); // Khởi tạo service
  Set<String> highlightedProvinces = {}; // Tập hợp ID tỉnh đã highlight
  bool isLoading = true; // Đang tải dữ liệu
  String? _originalSvgContent; // Nội dung SVG gốc
  String? _modifiedSvgContent; // SVG đã tô màu

  @override
  void initState() { // Khởi tạo khi màn hình được tạo
    super.initState();
    _loadInitialData(); // Tải dữ liệu ban đầu
  }

  // === HÀM XỬ LÝ SỰ KIỆN (GIỮ LẠI) ===
  void _navigateToOSM() { // Điều hướng sang bản đồ khu vực
    print("Điều hướng đến WorldMapScreen...");
    Navigator.push( // Mở màn hình mới
      context,
      MaterialPageRoute(
        builder: (context) => WorldMapScreen(userId: widget.userId),
      ),
    );
  }

  void _savePrivateLocation() { // Lưu địa điểm cá nhân
    print('Lưu địa điểm cá nhân...');
    // TODO: Triển khai logic
  }

  void _postReview() { // Đăng bài review
    print('Đăng bài...');
    // TODO: Triển khai logic
  }

  // === LOGIC TẢI DỮ LIỆU (ĐÃ GỌN GÀNG) ===
  Future<void> _loadInitialData() async { // Tải dữ liệu khi mở màn hình
    if (!mounted) return; // Kiểm tra widget còn tồn tại
    setState(() => isLoading = true); // Bật loading

    try {
      // 1. Tải SVG gốc
      _originalSvgContent = await rootBundle.loadString( // Đọc file SVG từ assets
        'assets/maps/vietnam_34_provinces.svg',
      );

      // 2. Tải data highlight (gọi Service)
      highlightedProvinces = await _mapService.loadHighlightedProvinces( // Lấy danh sách tỉnh cần tô
        widget.userId,
      );

      // 3. Tô màu SVG (dùng hàm từ helper)
      _modifiedSvgContent = colorSvgPaths( // Gọi hàm từ helper
        // SỬ DỤNG HÀM TỪ HELPER
        _originalSvgContent!,
        highlightedProvinces,
      );
    } catch (e) { // Bắt lỗi
      print("Lỗi tải dữ liệu ban đầu: $e");
      if (mounted) {
        _modifiedSvgContent = _originalSvgContent; // Dùng bản đồ gốc nếu lỗi
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    } finally { // Luôn chạy
      if (mounted) {
        setState(() => isLoading = false); // Tắt loading
      }
    }
  }

  // === HÀM TÔ MÀU (ĐÃ XÓA VÀ CHUYỂN SANG helper/svg_color_helper.dart) ===
  // String _colorSvgPaths(...) { ... } // ĐÃ DI CHUYỂN

  // === HÀM BUILD GIAO DIỆN (GIỮ NGUYÊN) ===
  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    int visitedCount = highlightedProvinces.length; // Số tỉnh đã đi

    return Scaffold(
      appBar: AppBar( // Thanh tiêu đề
        title: const Text('Travel Map'), // Tiêu đề
        actions: [ // Nút bên phải
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
      floatingActionButtonLocation: ExpandableFab.location, // Vị trí FAB
      floatingActionButton: JourneyMapFab( // Nút FAB mở rộng
        fabKey: _fabKey,
        onShowDetails: _showVisitedDetailsModal, // Xem chi tiết
        onOpenOsm: _navigateToOSM, // Mở bản đồ khu vực
        onSaveLocation: _savePrivateLocation, // Lưu địa điểm
        onPostReview: _postReview, // Đăng bài
      ),
      body: isLoading // Nếu đang tải
          ? const Center(child: CircularProgressIndicator()) // Hiển thị loading
          : Stack( // Lớp chồng lên nhau
              fit: StackFit.expand, // Chiếm toàn bộ
              children: [
                // 1. Lớp nền
                Image.asset( // Hình nền
                  'assets/images/map_background.jpg',
                  fit: BoxFit.cover, // Vừa khung
                ),
                // 2. Lớp bản đồ (Dùng widget mới)
                JourneyMapViewer( // Widget hiển thị SVG
                  modifiedSvgContent: _modifiedSvgContent,
                  originalSvgContent: _originalSvgContent,
                ),
                // 3. Lớp thống kê (Dùng widget mới)
                VisitedStatsBanner( // Banner thống kê
                  visitedCount: visitedCount,
                  totalCount: kAllProvinceIds.length, // Lấy từ constants
                ),
              ],
            ),
    );
  }

  // === HÀM HIỂN THỊ MODAL (GIỮ NGUYÊN) ===
  void _showVisitedDetailsModal() { // Mở modal chi tiết
    showModalBottomSheet( // Modal từ dưới lên
      context: context,
      isScrollControlled: true, // Cho phép cuộn
      shape: const RoundedRectangleBorder( // Bo góc trên
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // --- DÙNG WIDGET MỚI ---
        return VisitedProvincesModal( // Modal danh sách tỉnh
          highlightedProvinces: highlightedProvinces,
        );
      },
    );
  }
}