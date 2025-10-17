import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nhom_3_damh_lttbdd/screens/allColllectionsScreen.dart';

import 'addSaveItemScreen.dart';


// =========================================================================
// 1. MOCK DATA MODELS (Mô hình dữ liệu giả lập)
// =========================================================================

// Mô hình cho Địa điểm đã lưu (Dựa trên 'places' collection)
class Place {
  final String id;
  final String name;
  final String city;
  final String imageUrl;
  final double ratingAverage;

  Place({
    required this.id,
    required this.name,
    required this.city,
    required this.imageUrl,
    this.ratingAverage = 0.0,
  });
}

// Mô hình cho Bộ sưu tập Review theo Thành phố (Dựa trên 'reviews' collection)
class ReviewCollection {
  final String city;
  final String coverImageUrl;
  final int reviewCount;
  final String category; // ⚡️ ĐÃ THÊM: Thuộc tính Category

  ReviewCollection({
    required this.city,
    required this.coverImageUrl,
    required this.reviewCount,
    required this.category, // ⚡️ BẮT BUỘC
  });
}

// Dữ liệu giả cho các địa điểm đã lưu
final List<Place> mockSavedPlaces = [
  Place(
    id: 'p1',
    name: 'Dalat Palace Heritage Hotel',
    city: 'Đà Lạt',
    imageUrl:
    'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/1-1512755474911.jpg',
    ratingAverage: 4.8,
  ),
  Place(
    id: 'p2',
    name: 'Đà Lạt và hồ Xuân Tầm và những chuyến đi lãng mạn',
    city: 'Đà Lạt',
    imageUrl:
    'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/13-1512755474971.jpg',
    ratingAverage: 4.5,
  ),
  Place(
    id: 'p3',
    name: 'Tham quan Đại Nội Huế và khu vực Hoàng Thành',
    city: 'Huế',
    imageUrl:
    'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/13-1512755474971.jpg',
    ratingAverage: 4.7,
  ),
  Place(
    id: 'p4',
    name: 'Phố cổ Hội An',
    city: 'Hội An',
    imageUrl:
    'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/6-1512755474939.jpg',
    ratingAverage: 4.9,
  ),
  Place(
    id: 'p5',
    name: 'Bãi biển Mỹ Khê',
    city: 'Đà Nẵng',
    imageUrl:
    'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/6-1512755474939.jpg',
    ratingAverage: 4.9,
  ),
  Place(
    id: 'p6',
    name: 'Vịnh Hạ Long',
    city: 'Quảng Ninh',
    imageUrl:
    'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/6-1512755474939.jpg',
    ratingAverage: 4.9,
  ),
  Place(
    id: 'p7',
    name: 'Cầu Rồng Đà Nẵng',
    city: 'Đà Nẵng',
    imageUrl:
    'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/6-1512755474939.jpg',
    ratingAverage: 4.9,
  ),
];

// Dữ liệu giả cho các bộ sưu tập (nhóm theo city từ reviews)
final List<ReviewCollection> mockReviewCollections = [
  ReviewCollection(
    city: 'Đà Lạt',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-1.jpg',
    reviewCount: 45,
    category: 'Ẩm thực', // ⚡️ Category MỚI
  ),
  ReviewCollection(
    city: 'Hà Nội',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-12.jpg',
    reviewCount: 22,
    category: 'Tham quan', // ⚡️ Category MỚI
  ),
  ReviewCollection(
    city: 'TP. Hồ Chí Minh',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-17.jpg',
    reviewCount: 15,
    category: 'Khách sạn', // ⚡️ Category MỚI
  ),
  ReviewCollection(
    city: 'Hải Phòng',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-25.jpg',
    reviewCount: 8,
    category: 'Tham quan', // ⚡️ Category MỚI
  ),
  ReviewCollection(
    city: 'Nha Trang',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-25.jpg',
    reviewCount: 12,
    category: 'Ẩm thực', // ⚡️ Category MỚI
  ),
  ReviewCollection(
    city: 'Phú Quốc',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-25.jpg',
    reviewCount: 18,
    category: 'Khách sạn', // ⚡️ Category MỚI
  ),
  ReviewCollection(
    city: 'Sapa',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-25.jpg',
    reviewCount: 10,
    category: 'Tham quan', // ⚡️ Category MỚI
  ),
];


// =========================================================================
// 2. SAVED SCREEN (UI CỦA MÀN HÌNH ĐÃ LƯU)
// =========================================================================

class SavedScreen extends StatefulWidget {
  final String userId; // Dùng để truy vấn dữ liệu đã lưu của người dùng

  const SavedScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  // Hàm xử lý chuyển hướng (Bạn sẽ điền screen cụ thể sau)
  void _navigateToAllSavedItems() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AllSavedItemsScreen()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Chuyển đến màn hình "Tất cả sản phẩm đã lưu"')),
    );
  }

  void _navigateToCollectionDetail(String city) {
    // Navigator.push(context, MaterialPageRoute(builder: (context) => CollectionDetailScreen(city: city)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chuyển đến danh sách Review tại $city')),
    );
  }

  void _createNewCollection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở Modal tạo bộ sưu tập mới')),
    );
  }

  // ⚡️ Hàm chuyển sang màn hình Tất cả Bộ sưu tập
  void _navigateToAllCollections() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AllCollectionsScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đã lưu',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)), // Dùng GoogleFonts
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- THANH TÌM KIẾM ---
            _buildSearchBar(),
            const SizedBox(height: 24),

            // --- XEM TẤT CẢ SẢN PHẨM ĐÃ LƯU (HORIZONTAL LIST) ---
            _buildSavedItemsSection(),
            const SizedBox(height: 32),

            // --- BỘ SƯU TẬP (COLLECTIONS) ---
            _buildCollectionsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      // Giả lập Bottom Navigation Bar (Nếu cần)
      // bottomNavigationBar: ...
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.grey, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm đã lưu...',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Icon(Icons.filter_list, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSavedItemsSection() {
    final bool hasMore = mockSavedPlaces.length > 6;
    final int displayCount = hasMore ? 6 : mockSavedPlaces.length;
    final int itemCount = hasMore ? 7 : mockSavedPlaces.length; // +1 cho nút "Xem tất cả"

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⚡️ SỬA ĐỔI: Bọc Tiêu đề và Icon vào InkWell để tạo thành nút "Xem tất cả"
        InkWell(
          onTap: _navigateToAllSavedItems,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row( // KHẮC PHỤC LỖI: Sử dụng Row để kết hợp Text và Icon
                  children: [
                    Text(
                      'Xem tất cả các sản phẩm đã lưu',
                      style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18, color: Colors.black54), // Đã đổi sang Icons.arrow_forward
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 200, // Chiều cao cố định cho Horizontal ListView
          child: ListView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final isViewAllButton = hasMore && index == displayCount;

              if (isViewAllButton) {
                // ITEM THỨ 7: NÚT XEM TẤT CẢ (CHỈ XUẤT HIỆN KHI hasMore = true)
                return InkWell(
                  onTap: _navigateToAllSavedItems,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, width: 1.0),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_forward_ios, size: 30, color: Colors.orange.shade600),
                          const SizedBox(height: 8),
                          Text(
                            'Xem tất cả\n(${mockSavedPlaces.length} mục)',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // CÁC ITEM ĐÃ LƯU THÔNG THƯỜNG (Index 0 đến 5)
              final item = mockSavedPlaces[index];

              return InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Xem chi tiết: ${item.name}')));
                },
                borderRadius: BorderRadius.circular(10), // Bo góc cho InkWell

                child: Container(
                  width: 180, // Chiều rộng cố định cho toàn bộ Item
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10), // Bo góc cho Container
                    border: Border.all(color: Colors.grey.shade300, width: 1.0), // Viền
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- IMAGE (Phải bo góc riêng) ---
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          item.imageUrl,
                          width: 180,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 180,
                                height: 160,
                                color: Colors.grey[300],
                                child: const Center(child: Text('Ảnh lỗi')),
                              ),
                        ),
                      ),

                      // --- TEXT (CÓ PADDING VÀ XỬ LÝ TRÀN) ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: SizedBox(
                          width: 180, // Đảm bảo Text không tràn ra khỏi 180px
                          child: Text(
                            item.name,
                            textAlign:TextAlign.center ,
                            style: GoogleFonts.arima( // SỬ DỤNG GOOGLE FONTS
                              fontWeight: FontWeight.w700,
                              fontSize: 13.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 2. SỬA _buildCollectionsSection() (Bộ sưu tập Review)
  // =========================================================================
  Widget _buildCollectionsSection() {
    // Logic: 1 nút Tạo mới + 5 Collection + 1 nút Xem tất cả (nếu tổng > 6)
    final int collectionCount = mockReviewCollections.length;
    final bool hasMore = collectionCount > 5; // Cần 5 collection để hiển thị nút xem tất cả (1 slot cho Create)
    final int displayCollectionCount = hasMore ? 5 : collectionCount;
    // itemCount chỉ cần giới hạn là 6 (1 Create + 5 Item/Xem tất cả)
    final int itemCount = hasMore ? 6 : collectionCount + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bộ sưu tập',
          style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // --- GRIDVIEW CHO BỘ SƯU TẬP (Theo thành phố) ---
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(), // Không cuộn GridView
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 cột
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1, // Tỷ lệ chiều rộng/chiều cao
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {

            // ITEM 1: Nút Tạo bộ sưu tập mới (index == 0)
            if (index == 0) {
              return InkWell(
                onTap: _createNewCollection,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade400!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline,
                          color: Colors.green.shade700, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Tạo bộ sưu tập mới',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ⚡️ SỬA ĐỔI: Nút XEM TẤT CẢ (Vị trí cuối cùng nếu có nhiều hơn 5 collection)
            // Vị trí cuối cùng trong GridView bị giới hạn là 6 (index = 5)
            if (hasMore && index == 5) {
              return InkWell(
                // ⚡️ THAY THẾ: Gọi hàm chuyển màn hình
                onTap: _navigateToAllCollections,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300!),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.collections_bookmark_outlined, color: Colors.orange.shade600, size: 35),
                        const SizedBox(height: 8),
                        Text(
                          'Xem tất cả\nBộ sưu tập',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }


            // Các Bộ sưu tập Review theo thành phố (index 1 đến hết)
            // Lấy index của Collection thực tế: Nếu hasMore=true, ta phải trừ 1 (vì index 5 là nút Xem tất cả)
            final collectionIndex = index - 1;
            final collection = mockReviewCollections[collectionIndex];

            return InkWell(
              onTap: () => _navigateToCollectionDetail(collection.city),
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken,
                      ),
                      child: Image.network(
                        collection.coverImageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              color: Colors.blueGrey,
                              child: const Center(child: Text('Ảnh lỗi')),
                            ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          collection.city,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${collection.reviewCount} Reviews',
                          style:
                          GoogleFonts.montserrat(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Loại bỏ nút "Xem tất cả" cũ
        if (!hasMore && mockReviewCollections.isNotEmpty)
          const SizedBox(height: 24),
      ],
    );
  }
}
