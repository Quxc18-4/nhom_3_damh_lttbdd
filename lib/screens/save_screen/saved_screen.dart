import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nhom_3_damh_lttbdd/model/saved_models.dart';
import 'package:nhom_3_damh_lttbdd/screens/post_detail/post_detail_screen.dart';
import 'package:nhom_3_damh_lttbdd/screens/save_screen/all_collections_screen.dart';
import 'package:nhom_3_damh_lttbdd/screens/save_screen/service/saved_service.dart';
import 'package:nhom_3_damh_lttbdd/screens/save_screen/widgets/save_screen/saved_search_bar.dart';
import 'package:nhom_3_damh_lttbdd/screens/save_screen/widgets/save_screen/saved_items_section.dart';
import 'package:nhom_3_damh_lttbdd/screens/save_screen/widgets/save_screen/collections_section.dart';
import 'package:nhom_3_damh_lttbdd/screens/save_screen/all_saved_items_screen.dart';
import 'package:nhom_3_damh_lttbdd/screens/temp/postDetailScreen.dart'
    hide PostDetailScreen;
import 'package:nhom_3_damh_lttbdd/screens/save_screen/album_detail_screen.dart';

/// Màn hình "Đã lưu" — nơi người dùng xem các bài viết, địa điểm, album đã lưu
class SavedScreen extends StatefulWidget {
  final String userId; // ID của người dùng hiện tại

  const SavedScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  // Service để gọi và thao tác dữ liệu Firebase
  final SavedService _savedService = SavedService();

  // Future dùng để lưu trữ dữ liệu lấy từ Firebase
  Future<SavedItemsData>?
  _savedItemsFuture; // các mục đã lưu (bài review, địa điểm)
  late Future<List<Album>> _albumsFuture; // danh sách album (bộ sưu tập)

  SavedItemsData? _savedItemsCache; // lưu cache để giảm load
  bool _isInitialized = false; // cờ kiểm tra đã tải dữ liệu hay chưa

  @override
  void initState() {
    super.initState();
    _initializeData(); // gọi hàm khởi tạo dữ liệu khi widget được tạo
  }

  /// Hàm khởi tạo dữ liệu ban đầu
  Future<void> _initializeData() async {
    _fetchData(); // tải dữ liệu chính
    _savedService.fetchCategories(); // gọi song song (không cần chờ)
    setState(() {
      _isInitialized = true;
    });
  }

  /// Hàm lấy dữ liệu từ Firebase cho cả "đã lưu" và "album"
  void _fetchData() {
    // Lấy danh sách item đã lưu
    _savedItemsFuture = _savedService.fetchSavedItems(widget.userId).then((
      data,
    ) {
      if (mounted) {
        setState(() {
          _savedItemsCache = data;
        });
      }
      return data;
    });

    // Lấy danh sách album
    _albumsFuture = _savedService.fetchAlbums(widget.userId);
  }

  // -----------------------------
  // Các hàm điều hướng (navigation)
  // -----------------------------

  /// Chuyển đến màn hình hiển thị tất cả item đã lưu
  void _navigateToAllSavedItems() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllSavedItemsScreen(userId: widget.userId),
      ),
    );
  }

  /// Chuyển đến màn hình chi tiết của từng item
  void _navigateToItemDetail(SavedItem item) {
    if (item.category == SavedCategory.review) {
      // Nếu là bài review → mở chi tiết bài viết
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(reviewId: item.contentId),
        ),
      ).then((_) => _fetchData()); // Khi quay lại thì tải lại dữ liệu
    } else if (item.category == SavedCategory.place) {
      // Nếu là địa điểm (chưa có màn chi tiết) → thông báo tạm
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chuyển đến chi tiết Địa điểm (PlaceDetailScreen)'),
        ),
      );
    }
  }

  /// Chuyển đến chi tiết album cụ thể
  void _navigateToCollectionDetail(String albumId, String albumTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumDetailScreen(
          userId: widget.userId,
          albumId: albumId,
          albumTitle: albumTitle,
        ),
      ),
    ).then((_) => _fetchData()); // Reload dữ liệu khi quay lại
  }

  /// Chuyển đến màn hình xem tất cả bộ sưu tập
  void _navigateToAllCollections() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AllCollectionsScreen()),
    );
  }

  // -----------------------------
  // Tạo mới bộ sưu tập (Album)
  // -----------------------------

  /// Hiển thị dialog tạo album mới và lưu vào Firebase
  void _createNewCollection() async {
    final TextEditingController albumNameController = TextEditingController();

    // Mở dialog để nhập tên album
    final String? newAlbumName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Tạo bộ sưu tập mới"),
          content: TextField(
            controller: albumNameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Nhập tên..."),
          ),
          actions: [
            TextButton(
              child: const Text("Hủy"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text("Tạo"),
              onPressed: () {
                if (albumNameController.text.trim().isNotEmpty) {
                  // Trả lại tên album
                  Navigator.of(
                    dialogContext,
                  ).pop(albumNameController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );

    // Nếu người dùng nhập tên và xác nhận
    if (newAlbumName != null && newAlbumName.isNotEmpty) {
      try {
        // Gọi service để tạo album mới trên Firebase
        await _savedService.createAlbum(widget.userId, newAlbumName);

        // Cập nhật danh sách album hiển thị
        setState(() {
          _albumsFuture = _savedService.fetchAlbums(widget.userId);
        });
      } catch (e) {
        // Nếu lỗi → hiện thông báo
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Tạo bộ sưu tập thất bại: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // -----------------------------
  // Giao diện chính
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Đã lưu',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {}, // chưa xử lý
          ),
        ],
      ),

      // Nội dung chính của màn hình
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SavedSearchBar(), // thanh tìm kiếm (UI)
            const SizedBox(height: 24),

            // --- Khu vực các item đã lưu (bài viết, địa điểm...)
            SavedItemsSection(
              savedItemsFuture: _savedItemsFuture!,
              onViewAll: _navigateToAllSavedItems,
              onItemTap: _navigateToItemDetail,
            ),

            const SizedBox(height: 32),

            // --- Khu vực các bộ sưu tập (album)
            CollectionsSection(
              albumsFuture: _albumsFuture,
              onCreateNew: _createNewCollection,
              onViewAll: _navigateToAllCollections,
              onAlbumTap: _navigateToCollectionDetail,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
