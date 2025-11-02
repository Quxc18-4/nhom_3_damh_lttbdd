import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nhom_3_damh_lttbdd/screens/post_detail/post_detail_screen.dart';

// Model lưu thông tin từng item đã lưu
import '/model/saved_models.dart';

// Service xử lý logic tải dữ liệu các item đã lưu
import 'package:nhom_3_damh_lttbdd/screens/save_screen/service/all_saved_items_service.dart';

// Widget hiển thị chip lọc danh mục (Tất cả / Review / Place)
import 'package:nhom_3_damh_lttbdd/screens/save_screen/widgets/all_saved_items/category_filter_chips.dart';

// Widget hiển thị từng item (card)
import 'package:nhom_3_damh_lttbdd/screens/save_screen/widgets/all_saved_items/saved_item_card.dart';

// Màn hình chi tiết bài review
import 'package:nhom_3_damh_lttbdd/screens/temp/postDetailScreen.dart'
    hide PostDetailScreen;

/// ----------------------
/// MÀN HÌNH HIỂN THỊ TOÀN BỘ MỤC ĐÃ LƯU
/// ----------------------
class AllSavedItemsScreen extends StatefulWidget {
  final String userId; // ID của người dùng hiện tại

  const AllSavedItemsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<AllSavedItemsScreen> createState() => _AllSavedItemsScreenState();
}

class _AllSavedItemsScreenState extends State<AllSavedItemsScreen> {
  // Dịch vụ xử lý việc tải dữ liệu
  final AllSavedItemsService _service = AllSavedItemsService();

  // Danh mục hiện đang chọn (mặc định là tất cả)
  SavedCategory _selectedCategory = SavedCategory.all;

  // Future chứa danh sách tất cả các item đã lưu
  Future<List<SavedItem>>? _fullItemsFuture;

  // Cờ đánh dấu đã khởi tạo xong dữ liệu hay chưa
  bool _isInitialized = false;

  // Danh sách danh mục hiển thị filter chip
  final List<SavedCategory> _categories = [
    SavedCategory.all,
    SavedCategory.review,
    SavedCategory.place,
  ];

  @override
  void initState() {
    super.initState();
    _initializeData(); // Gọi hàm khởi tạo dữ liệu khi mở màn hình
  }

  /// Khởi tạo dữ liệu ban đầu
  Future<void> _initializeData() async {
    // Tải dữ liệu danh sách item và danh mục cùng lúc
    _fetchFullSavedItems();
    _service.fetchCategories();

    setState(() {
      _isInitialized = true;
    });
  }

  /// Gọi service để tải toàn bộ item đã lưu từ Firestore
  void _fetchFullSavedItems() {
    setState(() {
      _fullItemsFuture = _service.loadAllSavedItems(widget.userId);
    });
  }

  // =====================
  // XỬ LÝ ĐIỀU HƯỚNG
  // =====================

  /// Chuyển đến màn hình chi tiết khi nhấn vào item
  void _navigateToContentDetail(SavedItem item) {
    if (item.category == SavedCategory.review) {
      // Nếu là bài review → mở màn hình chi tiết bài viết
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(reviewId: item.contentId),
        ),
      ).then((_) => _fetchFullSavedItems()); // Cập nhật lại khi quay về
    } else if (item.category == SavedCategory.place) {
      // Nếu là địa điểm → tạm thời chỉ thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chuyển đến chi tiết Địa điểm (PlaceDetailScreen)'),
        ),
      );
    }
  }

  /// Hiển thị menu hành động khi giữ lâu 1 item (ví dụ: xóa khỏi mục lưu)
  void _showItemActionsSheet(SavedItem item) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Mở hành động cho: ${item.title}')));
  }

  // =====================
  // XÂY DỰNG GIAO DIỆN
  // =====================

  @override
  Widget build(BuildContext context) {
    // Nếu chưa khởi tạo xong → hiển thị vòng tròn loading
    if (!_isInitialized || _fullItemsFuture == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh filter danh mục (tất cả / review / place)
          CategoryFilterChips(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          // Danh sách item hiển thị bên dưới
          Expanded(child: _buildItemsList()),
        ],
      ),
    );
  }

  /// Thanh AppBar hiển thị tiêu đề
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Các sản phẩm đã lưu',
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  /// Widget hiển thị danh sách item đã lưu
  Widget _buildItemsList() {
    return FutureBuilder<List<SavedItem>>(
      future: _fullItemsFuture,
      builder: (context, snapshot) {
        // Trạng thái đang tải dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Nếu xảy ra lỗi khi tải dữ liệu
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
        }

        // Lấy danh sách item
        final allItems = snapshot.data ?? [];

        // Lọc theo danh mục người dùng đã chọn
        final items = _service.filterItemsByCategory(
          allItems,
          _selectedCategory,
        );

        // Nếu không có dữ liệu sau khi lọc
        if (items.isEmpty) {
          return Center(
            child: Text(
              'Không có mục đã lưu nào trong danh mục này.',
              style: GoogleFonts.montserrat(color: Colors.grey),
            ),
          );
        }

        // Hiển thị danh sách item
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return SavedItemCard(
              item: item,
              onTap: () => _navigateToContentDetail(item), // Bấm → xem chi tiết
              onLongPress: () => _showItemActionsSheet(item), // Giữ → menu
            );
          },
        );
      },
    );
  }
}
