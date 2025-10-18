import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =========================================================================
// 1. MOCK DATA MODELS VÀ ENUM
// =========================================================================

// Enum đại diện cho các loại hình (Category)
enum SavedCategory {
  all,
  hotel,
  activity,
  review, // Bài viết
}

// ⚡️ ĐÃ ĐỔI TÊN HÀM: categoryToVietnamese -> categoryToReview
String categoryToReview(SavedCategory category) {
  switch (category) {
    case SavedCategory.all:
      return 'Tất cả';
    case SavedCategory.hotel:
      return 'Khách sạn';
    case SavedCategory.activity:
      return 'Hoạt động du lịch';
    case SavedCategory.review:
      return 'Bài viết';
  }
}

// Mô hình cho một mục đã lưu (Tổng hợp thông tin cần hiển thị)
class SavedItem {
  final String id;
  final String title;
  final String subtitle;
  final SavedCategory category;
  final String imageUrl;
  final String ratingText; // VD: 9.5/10
  final String location;
  final String author; // Dành cho Bài viết

  SavedItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.imageUrl,
    required this.ratingText,
    required this.location,
    this.author = '',
  });
}

// Dữ liệu giả cho danh sách đã lưu
final List<SavedItem> mockAllSavedItems = [
  SavedItem(
    id: 's1',
    category: SavedCategory.review,
    title: 'Đà Lạt chào đón tôi bằng không khí se lạnh và những con đèo',
    subtitle: 'Đôi nét về chuyến đi Đà Lạt.',
    author: 'Khoa Pug',
    ratingText: '',
    location: '',
    imageUrl: 'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-1.jpg',
  ),
  SavedItem(
    id: 's2',
    category: SavedCategory.hotel,
    title: 'Dalat Palace Heritage Hotel',
    subtitle: 'Nơi lưu trú sang trọng tại Đà Lạt.',
    ratingText: '9.5/10 • 200 đánh giá',
    location: 'Trần Phú, Đà Lạt',
    imageUrl: 'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/1-1512755474911.jpg',
  ),
  SavedItem(
    id: 's3',
    category: SavedCategory.activity,
    title: 'Tham quan Đại Nội Huế và trải nghiệm cổ phục',
    subtitle: 'Trải nghiệm văn hóa lịch sử.',
    ratingText: '9.4/10 • 253 đánh giá',
    location: 'Phường Phú Hội, Huế',
    imageUrl: 'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/13-1512755474971.jpg',
  ),
  SavedItem(
    id: 's4',
    category: SavedCategory.hotel,
    title: 'Khách sạn Mường Thanh Đà Nẵng',
    subtitle: 'Khách sạn ven biển chất lượng tốt.',
    ratingText: '8.8/10 • 450 đánh giá',
    location: 'Bãi biển Mỹ Khê, Đà Nẵng',
    imageUrl: 'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/6-1512755474939.jpg',
  ),
];

// =========================================================================
// 2. ALL SAVED ITEMS SCREEN
// =========================================================================

class AllSavedItemsScreen extends StatefulWidget {
  const AllSavedItemsScreen({Key? key}) : super(key: key);

  @override
  State<AllSavedItemsScreen> createState() => _AllSavedItemsScreenState();
}

class _AllSavedItemsScreenState extends State<AllSavedItemsScreen> {
  SavedCategory _selectedCategory = SavedCategory.all;

  // Lấy danh sách mục đã lưu dựa trên category được chọn
  List<SavedItem> get _filteredItems {
    if (_selectedCategory == SavedCategory.all) {
      return mockAllSavedItems;
    }
    return mockAllSavedItems
        .where((item) => item.category == _selectedCategory)
        .toList();
  }

  // Danh sách các category để hiển thị thanh lọc
  final List<SavedCategory> _categories = [
    SavedCategory.all,
    SavedCategory.hotel,
    SavedCategory.activity,
    SavedCategory.review,
  ];

  // --- HÀM HIỂN THỊ BOTTOM SHEET (ACTION MODAL) ---
  void _showItemActionsSheet(SavedItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TIÊU ĐỀ VÀ NÚT ĐÓNG ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bạn muốn làm gì?',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20, thickness: 1),

              // --- CÁC TÙY CHỌN HÀNH ĐỘNG ---
              _buildActionTile(
                icon: Icons.bookmark_add_outlined,
                title: 'Thêm vào bộ sưu tập',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mục "${item.title}" đã được thêm vào bộ sưu tập.')),
                  );
                },
              ),
              _buildActionTile(
                icon: Icons.delete_outline,
                title: 'Xóa',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Xóa mục "${item.title}" khỏi danh sách đã lưu.')),
                  );
                  // TODO: Thêm logic xóa thực tế và cập nhật state/UI
                },
              ),
              _buildActionTile(
                icon: Icons.share_outlined,
                title: 'Chia sẻ',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chia sẻ mục "${item.title}"')),
                  );
                  // TODO: Thêm logic chia sẻ
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget: Một hàng tùy chọn trong Bottom Sheet
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Các sản phẩm đã lưu',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- THANH LỌC (FILTERS) ---
          _buildFilterChips(),

          // --- DANH SÁCH MỤC ĐÃ LƯU ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return _buildSavedItemCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget: Thanh lọc ngang (Không thay đổi)
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = category == _selectedCategory;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                label: Text(
                  categoryToReview(category),
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
                backgroundColor: isSelected ? Colors.orange.shade600 : Colors.grey.shade200,
                onPressed: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.orange.shade600! : Colors.grey.shade300,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget: Thẻ hiển thị một mục đã lưu
  Widget _buildSavedItemCard(SavedItem item) {
    bool isReview = item.category == SavedCategory.review;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ẢNH ITEM ---
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Image.network(
                      item.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                    // --- CHIP Category ---
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isReview ? Colors.lightBlue.shade700 : Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          categoryToReview(item.category),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // --- THÔNG TIN & TIÊU ĐỀ ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Menu 3 chấm (ĐÃ SỬA ĐỔI)
                        IconButton(
                          onPressed: () => _showItemActionsSheet(item), // ⚡️ GỌI ACTION SHEET
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Rating/Author
                    if (!isReview)
                      Text(
                        item.ratingText,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.person_pin, size: 16, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            item.author,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 4),

                    // Location
                    if (!isReview)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.red.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.5),

          // --- NÚT THÊM VÀO BỘ SƯU TẬP ---
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Thêm ${item.title} vào Bộ sưu tập')));
                },
                child: Row(
                  children: [
                    Icon(Icons.bookmark_add_outlined, size: 18, color: Colors.orange.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Thêm vào Bộ sưu tập',
                      style: GoogleFonts.montserrat(
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
